package jnamailslot;

import java.sql.Time;
import java.util.Date;

import com.sun.jna.Memory;
import com.sun.jna.ptr.IntByReference;

public class MailSlotTest {

	JNAKernel32 k32lib;
	int lastError = 0;
	int nextMsgSize = 0;

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		new MailSlotTest();

	}

	public MailSlotTest() {
		k32lib = JNAKernel32.INSTANCE;
		//String host = "pc-seki";
		String host = ".";
		String slot = "javaslot";

		System.out.println("Mailslot java test");
		System.out.println("==================\n");
		ClientTest(host, slot);
		ServerTest(slot);
	}

	public void ClientTest(String host, String slotPath){
		String fullPath = "\\\\" + host + "\\mailslot\\" + slotPath;
		String msg = "Message envoyé par java à " + new Date().toString();
		IntByReference written = new IntByReference();
		
		System.out.println("ClientTest");
		System.out.println("----------");

		System.out.println("Envoi du message `" + msg + "` vers " + fullPath);
		int hFile = k32lib.CreateFile(fullPath, JNAKernel32.GENERIC_WRITE, JNAKernel32.FILE_SHARE_READ, 0, JNAKernel32.CREATE_ALWAYS, JNAKernel32.FILE_ATTRIBUTE_NORMAL, 0);
		if (hFile != JNAKernel32.INVALID_HANDLE_VALUE){
			k32lib.WriteFile(hFile, msg, msg.length() * 2, written, 0);
			System.out.println("Envoyé " + Integer.toString(written.getValue()) + " octets");
			k32lib.CloseHandle(hFile);
		}
	}
	
	public void ServerTest(String slotPath){
		
		System.out.println("\nServerTest");
		System.out.println("------------");
		
		if (!MailslotExists(".", slotPath)){
			int hSlot = CreateMailSlot(slotPath, 256, JNAKernel32.MAILSLOT_WAIT_FOREVER);
			
			if (hSlot > 0){
				System.out.println("hSlot \\\\.\\mailslot\\" + slotPath + " = " + Integer.toString(hSlot));
	
				try {
					while (!hasMessage(hSlot)){
						Thread.sleep(1000);
					}
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				
				//Memory msg = new Memory(nextMsgSize);
				byte[] msg = new byte[nextMsgSize * 2];
				IntByReference read = new IntByReference();
				k32lib.ReadFile(hSlot, msg, nextMsgSize, read, 0);
				
				//System.out.println("Reçu msg dans mailslot :" + msg.getString(nextMsgSize));
				System.out.println("Reçu msg dans mailslot :" + b2s(msg));
	
				k32lib.CloseHandle(hSlot);
			}
			else
				System.out.println("CreateMailSlot failed."); 
		}else
			System.out.println("Creation du Mailslot impossible : il existe déjà.");
	}

	public int CreateMailSlot(String path, int maxSize, int timeOut){
		String slotPath = "\\\\.\\mailslot\\" + path;
		
		int hSlot = k32lib.CreateMailslot(slotPath, maxSize, timeOut, 0);
		if (hSlot == JNAKernel32.INVALID_HANDLE_VALUE)
			lastError = k32lib.GetLastError();
		
		return hSlot;
	}
	
	public boolean MailslotExists(String host, String path){
		String fullPath = "\\\\" + host + "\\mailslot\\" + path;
		int hFile = k32lib.CreateFile(fullPath, JNAKernel32.GENERIC_READ + JNAKernel32.GENERIC_WRITE, JNAKernel32.FILE_SHARE_READ, 0, JNAKernel32.OPEN_EXISTING, 0, 0);
		if (hFile != JNAKernel32.INVALID_HANDLE_VALUE){
			k32lib.CloseHandle(hFile);
			return true;
		}
		return false;
	}
	
	public boolean hasMessage(int hSlot){
		IntByReference maxMsg = new IntByReference();
		IntByReference nextMsg = new IntByReference();
		IntByReference msgCount = new IntByReference();
		IntByReference timeOut = new IntByReference();
		
		if (k32lib.GetMailslotInfo(hSlot, maxMsg, nextMsg, msgCount, timeOut)){
			nextMsgSize = nextMsg.getValue();
			return msgCount.getValue() > 0;
		} else
			return false;
	}
	
	private static String b2s(byte b[]) {
	    // Converts C string to Java String
	    int len = 0;
	    while (b[len] != 0)
	      len += 2; // au lieu de ++
	    return new String(b, 0, len);
	  }
}
