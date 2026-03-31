package sd.lab1;

import java.net.* ;
import java.util.*;

/**
 * Basic TCP client... 
 *
 */
public class TcpClient {
    
	private static final String QUIT = "!quit";

	public static void main(String[] args) throws Exception {
        
    	// MUDEI ISTO: agora usa Discovery para descobrir servidores automaticamente (antes pedia input manual do usuário)
		// Conforme indicado no PDF página 45-46
		System.out.println("Discovering TcpServer instances...");
		
		Discovery discovery = new Discovery(Discovery.DISCOVERY_ADDR);
		discovery.start();
		
		// MUDEI ISTO: aguarda descobrir pelo menos 1 servidor via multicast
		java.net.URI[] servers = discovery.knownUrisOf("TcpServer", 1);
		
		if (servers.length == 0) {
			System.err.println("No TcpServer instances found!");
			return;
		}
		
		// MUDEI ISTO: usa o primeiro servidor descoberto (em vez de pedir ao usuário)
		java.net.URI serverUri = servers[0];
		String hostname = serverUri.getHost();
		int port = serverUri.getPort();
		
		System.out.println("Connecting to discovered server: " + serverUri);
		
    	// FEITO DE INICIO: Estabelece conexão TCP e envia linhas até receber !quit
		Scanner scan = new Scanner(System.in);
    	try( Socket sock = new Socket( hostname, port)) {
    		String input;
    		do {
    			input = scan.nextLine();
    			sock.getOutputStream().write( (input + System.lineSeparator()).getBytes() );
    		} while( ! input.equals(QUIT));
    		
    	}
    	
    	scan.close();
		
    }  
}
