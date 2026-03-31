package sd.lab1;

import java.net.* ;
import java.util.logging.Logger;

/**
 * Basic TCP server... 
 *
 */
public class TcpServer {
	private static Logger Log = Logger.getLogger(TcpServer.class.getName());

    private static final int PORT = 9000;
	private static final int BUF_SIZE = 1024;

	public static void main(String[] args) throws Exception {
        
		// MUDEI ISTO: adicionei Discovery para o servidor se auto-anunciar (antes estava TODO)
		// Formato do URI: tcp://hostname:port (conforme indicado no PDF página 42-44)
		String hostname = InetAddress.getLocalHost().getHostAddress();
		String serviceURI = "tcp://" + hostname + ":" + PORT;
		
		Discovery discovery = new Discovery(Discovery.DISCOVERY_ADDR, "TcpServer", serviceURI);
		discovery.start();
		
		Log.info("Service announced as: " + serviceURI);

        
		// FEITO DE INICIO: Cria server socket e aguarda conexões TCP dos clientes
		try(ServerSocket ssocket = new ServerSocket( PORT )) {
			Log.info("My IP address is: " + hostname);
			Log.info("Accepting connections at: " + ssocket.getLocalSocketAddress() ) ;
            while( true ) {
                Socket csocket = ssocket.accept() ;
                
                System.err.println("Accepted connection from client at: " + csocket.getRemoteSocketAddress() ) ;
                
                int n;
                byte[] buf = new byte[ BUF_SIZE];
                
                // FEITO DE INICIO: Recebe linhas de texto do cliente e imprime
                while( (n = csocket.getInputStream().read(buf)) > 0)
                	System.out.write( buf, 0, n);
                
                Log.info("Connection closed.") ;
            }        	
        }
    }
    
}
