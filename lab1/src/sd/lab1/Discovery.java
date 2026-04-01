package sd.lab1;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.MulticastSocket;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.URI;
import java.net.UnknownHostException;
import java.util.logging.Logger;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * <p>
 * A class to perform service discovery, based on periodic service contact
 * endpoint announcements over multicast communication.
 * </p>
 * 
 * <p>
 * Servers announce their *name* and contact *uri* at regular intervals. The
 * server actively collects received announcements.
 * </p>
 * 
 * <p>
 * Service announcements have the following format:
 * </p>
 * 
 * <p>
 * &lt;service-name-string&gt;&lt;delimiter-char&gt;&lt;service-uri-string&gt;
 * </p>
 */
public class Discovery {
	private static Logger Log = Logger.getLogger(Discovery.class.getName());

	static {
		// addresses some multicast issues on some TCP/IP stacks
		System.setProperty("java.net.preferIPv4Stack", "true");
		// summarizes the logging format
		System.setProperty("java.util.logging.SimpleFormatter.format", "%4$s: %5$s");
	}

	// The pre-aggreed multicast endpoint assigned to perform discovery.
	// Allowed IP Multicast range: 224.0.0.1 - 239.255.255.255
	static final public InetSocketAddress DISCOVERY_ADDR = new InetSocketAddress("226.226.226.226", 2266);
	static final int DISCOVERY_ANNOUNCE_PERIOD = 1000;
	static final int DISCOVERY_RETRY_TIMEOUT = 5000;
	static final int MAX_DATAGRAM_SIZE = 65536;

	// Used separate the two fields that make up a service announcement.
	private static final String DELIMITER = "\t";

	private final InetSocketAddress addr;
	private final String serviceName; // FEITO DE INICIO: nome do serviço a anunciar (pode ser null se só queremos descobrir)
	private final String serviceURI;  // FEITO DE INICIO: URI do serviço a anunciar (pode ser null se só queremos descobrir)
	private final MulticastSocket ms; // FEITO DE INICIO: socket multicast para enviar/receber anúncios
	
	// MUDEI ISTO: em vez de só guardar URIs, agora guardamos URIs com timestamps (para saber quando foi o último anúncio)
	// Estrutura: serviceName -> Map<URI, timestamp_do_ultimo_anuncio>
	private final Map<String, Map<URI, Long>> serviceRegistry = new ConcurrentHashMap<>();
	/**
	 * FEITO DE INICIO: Construtor para criar instância que vai ANUNCIAR um serviço
	 * @param serviceName the name of the service to announce
	 * @param serviceURI  an uri string - representing the contact endpoint of the
	 *                    service being announced
	 * @throws IOException 
	 * @throws UnknownHostException 
	 * @throws SocketException 
	 */
	Discovery(InetSocketAddress addr, String serviceName, String serviceURI) throws SocketException, UnknownHostException, IOException {
		this.addr = addr;
		this.serviceName = serviceName;
		this.serviceURI = serviceURI;

		if (this.addr == null) {
			throw new RuntimeException("A multinet address has to be provided.");
		} 
		
		// FEITO DE INICIO: cria socket multicast e junta-se ao grupo para receber mensagens
		this.ms = new MulticastSocket(addr.getPort());
		this.ms.joinGroup(addr, NetworkInterface.getByInetAddress(InetAddress.getLocalHost()));
	}

	/**
	 * FEITO DE INICIO: Construtor para criar instância que SÓ descobre serviços (não anuncia)
	 */
	Discovery(InetSocketAddress addr) throws SocketException, UnknownHostException, IOException {
		this(addr, null, null);
	}

	/**
	 * FEITO DE INICIO: Inicia os threads de anúncio (se aplicável) e receção de anúncios
	 * @throws IOException 
	 */
	public void start() {
		// FEITO DE INICIO: Se esta instância tem serviceName e serviceURI, inicia thread para anunciar periodicamente
		if (this.serviceName != null && this.serviceURI != null) {

			Log.info(String.format("Starting Discovery announcements on: %s for: %s -> %s", addr, serviceName,
					serviceURI));

			// FEITO DE INICIO: prepara o pacote de anúncio com formato "serviceName\tserviceURI"
			byte[] announceBytes = String.format("%s%s%s", serviceName, DELIMITER, serviceURI).getBytes();
			DatagramPacket announcePkt = new DatagramPacket(announceBytes, announceBytes.length, addr);

			try {
				// FEITO DE INICIO: thread para enviar anúncios periódicos (a cada 1 segundo)
				new Thread(() -> {
					for (;;) {
						try {
							ms.send(announcePkt);
							Thread.sleep(DISCOVERY_ANNOUNCE_PERIOD);
						} catch (Exception e) {
							e.printStackTrace();
							// do nothing
						}
					}
				}).start();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		// FEITO DE INICIO: thread para receber anúncios da rede multicast
		new Thread(() -> {
			DatagramPacket pkt = new DatagramPacket(new byte[MAX_DATAGRAM_SIZE], MAX_DATAGRAM_SIZE);
			for (;;) {
				try {
					pkt.setLength(MAX_DATAGRAM_SIZE);
					ms.receive(pkt); // FEITO DE INICIO: bloqueia até receber mensagem multicast
					String msg = new String(pkt.getData(), 0, pkt.getLength());
					String[] msgElems = msg.split(DELIMITER);
					
					if (msgElems.length == 2) { // FEITO DE INICIO: validar formato "serviceName\tserviceURI"
						String announcedServiceName = msgElems[0];
						String announcedServiceURI = msgElems[1];
						
						System.out.printf("FROM %s (%s) : %s\n", pkt.getAddress().getHostName(),
								pkt.getAddress().getHostAddress(), msg);
						
						// MUDEI ISTO: agora gravo o URI com o timestamp do anúncio (conforme sugestão do PDF)
						try {
							URI uri = URI.create(announcedServiceURI);
							long currentTime = System.currentTimeMillis();
							
							// Cria entrada para o serviço se não existir, e adiciona/atualiza URI com timestamp atual
							serviceRegistry.computeIfAbsent(announcedServiceName, k -> new ConcurrentHashMap<>())
								.put(uri, currentTime);
							
							Log.info(String.format("Registered service: %s -> %s (timestamp: %d)", 
								announcedServiceName, uri, currentTime));
						} catch (Exception e) {
							Log.warning(String.format("Invalid URI received: %s", announcedServiceURI));
						}
					}
				} catch (IOException e) {
					// do nothing
				}
			}
		}).start();
	}

	/**
	 * MUDEI ISTO: implementei este método que estava com TODO (throw Error)
	 * Retorna URIs de serviços descobertos, esperando até ter minReplies ou timeout
	 * 
	 * @param serviceName the name of the service being discovered
	 * @param minReplies  - minimum number of requested URIs. Blocks until the
	 *                    number is satisfied.
	 * @return an array of URI with the service instances discovered.
	 * 
	 */
	public URI[] knownUrisOf(String serviceName, int minReplies) {
		Log.info(String.format("Searching for '%s' with minimum %d replicas...", serviceName, minReplies));
		
		long startTime = System.currentTimeMillis();
		
		// MUDEI ISTO: bloqueia até ter minReplies URIs ou timeout
		while (true) {
			Map<URI, Long> uriMap = serviceRegistry.get(serviceName);
			
			// MUDEI ISTO: retorna TODOS os URIs registados (mesmo com timestamps antigos)
			// É responsabilidade do programador verificar se os timestamps são recentes
			if (uriMap != null && uriMap.size() >= minReplies) {
				URI[] uris = uriMap.keySet().toArray(new URI[0]);
				Log.info(String.format("Found %d instances of service '%s'", uris.length, serviceName));
				return uris;
			}
			
			// MUDEI ISTO: verifica timeout de 5 segundos
			long elapsed = System.currentTimeMillis() - startTime;
			if (elapsed > DISCOVERY_RETRY_TIMEOUT) {
				int found = (uriMap != null) ? uriMap.size() : 0;
				Log.warning(String.format("Timeout waiting for service '%s' (found %d, needed %d)", 
					serviceName, found, minReplies));
				// Retorna o que tem, mesmo se for menos que minReplies
				return (uriMap != null) ? uriMap.keySet().toArray(new URI[0]) : new URI[0];
			}
			
			// MUDEI ISTO: sleep curto antes de verificar novamente (polling a cada 100ms)
			try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				Thread.currentThread().interrupt();
				return new URI[0];
			}
		}
	}

	// FEITO DE INICIO: Main apenas para testes
	public static void main(String[] args) throws Exception {
		Discovery discovery = new Discovery(DISCOVERY_ADDR, "test",
				"http://" + InetAddress.getLocalHost().getHostAddress());
		discovery.start();
	}
}
