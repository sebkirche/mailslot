HA$PBExportHeader$nv_mailslot.sru
forward
global type nv_mailslot from nonvisualobject
end type
end forward

global type nv_mailslot from nonvisualobject autoinstantiate
end type

type prototypes

private function ulong CreateMailslot(ref string lpName, ulong nMaxMessageSize, ulong lReadTimeout, ulong lpSecurityAttributes) library "Kernel32.dll" alias for "CreateMailslotW"
private function boolean CloseHandle (ulong hObject) Library "kernel32.dll" 
private function boolean GetMailslotInfo (ulong hMailslot, ref ulong lpMaxMessageSize, ref ulong lpNextSize, ref ulong lpMessageCount, ref ulong lpReadTimeout) library "kernel32.dll"
private function boolean SetMailslotInfo (ulong hMailslot, ulong lReadTimeout) library "kernel32.dll"
private function ulong CreateFile (string lpFileName, ulong dwDesiredAccess, ulong dwShareMode, ulong lpSecurityAttributes, ulong dwCreationDisposition, ulong dwFlagsAndAttributes, ulong hTemplateFile) library "kernel32.dll" alias for "CreateFileW"
private function boolean ReadFile (ulong hFile, ref string lpBuffer, ulong nNumberOfBytesToRead, ref ulong lpNumberOfBytesRead, ulong lpOverlapped) library "kernel32.dll"
private function boolean WriteFile (ulong hFile, ref string lpBuffer, ulong nNumberOfBytesToWrite, ref ulong lpNumberOfBytesWritten, ulong lpOverlapped) library "kernel32.dll"
private function ulong GetLastError() library "kernel32.dll"

end prototypes

type variables

/* Mailslot paths : (http://msdn.microsoft.com/en-us/library/aa365147(VS.85).aspx)

\\.\mailslot\[path]name						Retrieves a client handle to a local mailslot.
\\computername\mailslot\[path]name		Retrieves a client handle to a remote mailslot.
\\domainname\mailslot\[path]name			Retrieves a client handle to all mailslots with the specified name in the specified domain.
\\*\mailslot\[path]name						Retrieves a client handle to all mailslots with the specified name in the system's primary domain.

Max size for a message :
- 64 kB for a local msg
- 423 bytes for a broadcast

*/

//return values
constant ulong INVALID_HANDLE_VALUE = -1
constant ulong MAILSLOT_NO_MESSAGE = -1

//timeout
constant ulong MAILSLOT_WAIT_FOREVER = -1

//msg sizes
constant ulong MSG_ANY_SIZE = 0
constant ulong MSG_DEFAULT_BUFFER = 8192

//file access
constant ulong GENERIC_READ  = 2147483648 //0x80000000
constant ulong GENERIC_WRITE = 1073741824 //0x40000000

//file shares
constant ulong FILE_SHARE_READ = 1
constant ulong FILE_SHARE_WRITE = 2
constant ulong FILE_SHARE_DELETE = 4

//creation types
constant ulong CREATE_ALWAYS = 2
constant ulong CREATE_NEW = 1
constant ulong OPEN_ALWAYS = 4
constant ulong OPEN_EXISTING = 3
constant ulong TRUNCATE_EXISTING = 5

//file attributes
constant ulong FILE_ATTRIBUTE_NORMAL = 128

private:
string is_fullpath = ""
ulong iul_max_size
ulong iul_slot = INVALID_HANDLE_VALUE


end variables

forward prototypes
public function boolean exists (string as_host, string as_path)
public function string read (unsignedlong aul_mslot)
public function boolean send (string as_host, string as_path, string as_msg)
public function boolean exists (string as_path)
public function boolean send (string as_path, string as_msg)
public function string readwithwait (unsignedlong aul_mslot)
public function string getfullpath ()
public function boolean close ()
public function string read ()
public function string readwithwait ()
public function unsignedlong getmessagescount ()
public function boolean getinfos (unsignedlong aul_slot, ref unsignedlong aul_maxmsg, ref unsignedlong aul_nextmsg, ref unsignedlong aul_msgcount, ref unsignedlong aul_timeout)
public function unsignedlong getnextsize ()
public function boolean hasmessage ()
public function boolean settimeout (unsignedlong aul_timeout)
public function boolean send (unsignedlong aul_slot, string as_msg)
public function boolean send (string as_msg)
public function boolean open (string as_path)
public function boolean open (string as_path, unsignedlong aul_maxsize, unsignedlong aul_timeout)
public function boolean isopened ()
private function ulong create (string as_path, unsignedlong aul_maxsize, unsignedlong aul_timeout)
end prototypes

public function boolean exists (string as_host, string as_path);// Test the existence of a mailslot

boolean lb_ret = false
string ls_path

ls_path = "\\" + as_host + "\mailslot\" + as_path

return exists(ls_path)

end function

public function string read (unsignedlong aul_mslot);// read the next waiting message

boolean lb_ret
ulong lul_maxmsg, lul_nextmsg, lul_msgcount = 0, lul_timeout, lul_read
string ls_buf = ""

if GetMailslotinfo( aul_mslot, lul_maxmsg, lul_nextmsg /*bytes*/, lul_msgcount, lul_timeout) and lul_msgcount > 0 then
	ls_buf = space(lul_nextmsg / 2)
	lb_ret = readfile(aul_mslot, ls_buf, lul_nextmsg, lul_read /*bytes*/, 0)
	
	if lb_ret and (lul_read = lul_nextmsg) then
		ls_buf = left(ls_buf, lul_read / 2)
	end if
end if

return ls_buf

end function

public function boolean send (string as_host, string as_path, string as_msg);// send a message to the mailslot

string ls_path

ls_path = "\\" + as_host + "\mailslot\" + as_path

return send(ls_path, as_msg)

end function

public function boolean exists (string as_path);// Test the existence of a mailslot

boolean lb_ret = false
ulong hFile

//try to open existing
hFile = CreateFile(as_path, generic_read + generic_write, file_share_read, 0, open_existing, 0, 0)
if hfile <> INVALID_HANDLE_VALUE then
	lb_ret = true
	Closehandle( hfile )
end if

return lb_ret

end function

public function boolean send (string as_path, string as_msg);// send a message to the mailslot

boolean lb_ret = false
ulong hFile

hFile = CreateFile(as_path, generic_write, file_share_read, 0, create_always /* CREATE_NEW */ , file_attribute_normal, 0)
if hfile <> INVALID_HANDLE_VALUE then
	lb_ret = Send(hfile, as_msg)
	Closehandle( hfile )
end if

return lb_ret

end function

public function string readwithwait (unsignedlong aul_mslot);// read the next waiting message

boolean lb_ret
ulong lul_maxmsg, lul_nextmsg, lul_msgcount = 0, lul_timeout, lul_read
string ls_buf = ""

if GetMailslotinfo( aul_mslot, lul_maxmsg, lul_nextmsg/*bytes*/, lul_msgcount, lul_timeout) then
	if lul_nextmsg = MAILSLOT_NO_MESSAGE then
		if lul_maxmsg > 0 then
			lul_nextmsg = lul_maxmsg
		else
			lul_nextmsg = msg_default_buffer
		end if
	end if
	ls_buf = space(lul_nextmsg / 2) 
	lb_ret = readfile(aul_mslot, ls_buf, lul_nextmsg, lul_read/*bytes*/, 0)
	
	if lb_ret then
		ls_buf = left(ls_buf, lul_read / 2)
	end if
end if

return ls_buf

end function

public function string getfullpath ();
return is_fullpath

end function

public function boolean close ();// Close a mailslot

boolean lb_ret
lb_ret = CloseHandle( iul_slot )
iul_slot = invalid_handle_value

return lb_ret

end function

public function string read ();// read the next waiting message
// if no message, returns

boolean lb_ret
ulong lul_maxmsg, lul_nextmsg, lul_msgcount = 0, lul_timeout, lul_read
string ls_buf = ""

if GetMailslotinfo( iul_slot, lul_maxmsg, lul_nextmsg /*bytes*/, lul_msgcount, lul_timeout) and lul_msgcount > 0 then
	ls_buf = space(lul_nextmsg / 2)
	lb_ret = readfile(iul_slot, ls_buf, lul_nextmsg, lul_read /*bytes*/, 0)
	
	if lb_ret and (lul_read = lul_nextmsg) then
		ls_buf = left(ls_buf, lul_read / 2)
	end if
end if

return ls_buf

end function

public function string readwithwait ();// read the next waiting message
// if no message, wait until there is a message or timeout

boolean lb_ret
ulong lul_maxmsg, lul_nextmsg, lul_msgcount = 0, lul_timeout, lul_read
string ls_buf = ""

if GetMailslotinfo( iul_slot, lul_maxmsg, lul_nextmsg/*bytes*/, lul_msgcount, lul_timeout) then
	if lul_nextmsg = MAILSLOT_NO_MESSAGE then
		if lul_maxmsg > 0 then
			lul_nextmsg = lul_maxmsg
		else
			lul_nextmsg = msg_default_buffer
		end if
	end if
	ls_buf = space(lul_nextmsg / 2) 
	lb_ret = readfile(iul_slot, ls_buf, lul_nextmsg, lul_read/*bytes*/, 0)
	
	if lb_ret then
		ls_buf = left(ls_buf, lul_read / 2)
	end if
end if

return ls_buf

end function

public function unsignedlong getmessagescount ();// Tells if the given mailslot has waiting messages

ulong lul_maxmsg, lul_nextmsg, lul_msgcount, lul_timeout

if GetInfos( iul_slot, lul_maxmsg, lul_nextmsg, lul_msgcount, lul_timeout) then
	return lul_msgcount
else
	return 0
end if


end function

public function boolean getinfos (unsignedlong aul_slot, ref unsignedlong aul_maxmsg, ref unsignedlong aul_nextmsg, ref unsignedlong aul_msgcount, ref unsignedlong aul_timeout);// Get informations about the mailslot

boolean lb_ret

lb_ret = GetMailslotinfo( aul_slot, aul_maxmsg, aul_nextmsg, aul_msgcount, aul_timeout)

return lb_ret

end function

public function unsignedlong getnextsize ();// Tells the size of the next message in bytes in the mailslot if any

ulong lul_maxmsg, lul_nextmsg, lul_msgcount, lul_timeout

if GetInfos(iul_slot, lul_maxmsg, lul_nextmsg, lul_msgcount, lul_timeout) then
	return lul_nextmsg
else
	return 0
end if

end function

public function boolean hasmessage ();// Tells if the given mailslot has waiting messages

ulong lul_count

lul_count = GetMessagesCount( ) 

return lul_count > 0

end function

public function boolean settimeout (unsignedlong aul_timeout);// Modify the mailslot read timeout

boolean lb_ret

lb_ret = SetMailslotInfo( iul_slot, aul_timeout)

return lb_ret

end function

public function boolean send (unsignedlong aul_slot, string as_msg);// send a message to the mailslot

boolean lb_ret
ulong lul_len, lul_written

lul_len = len(as_msg)
if (iul_max_size > 0) and (lul_len > iul_max_size) then return false

lb_ret = WriteFile( aul_slot, as_msg, len(as_msg) * 2, lul_written, 0)
lb_ret = lul_len = lul_written

return lb_ret

end function

public function boolean send (string as_msg);// send a message to the mailslot

boolean lb_ret
ulong lul_len, lul_written

lul_len = len(as_msg)
if (iul_max_size > 0) and (lul_len > iul_max_size) then return false

lb_ret = WriteFile( iul_slot, as_msg, len(as_msg) * 2, lul_written, 0)
lb_ret = lul_len = lul_written

return lb_ret

end function

public function boolean open (string as_path);// Open a mailslot
//
// it can only be a local mailslot

return open(as_path, msg_any_size, 0)

end function

public function boolean open (string as_path, unsignedlong aul_maxsize, unsignedlong aul_timeout);// Create a mailslot
//
// it can only be a local mailslot

iul_slot = create(as_path, aul_maxsize, aul_timeout)

return iul_slot <> invalid_handle_value

end function

public function boolean isopened ();
return iul_slot <> INVALID_HANDLE_VALUE

end function

private function ulong create (string as_path, unsignedlong aul_maxsize, unsignedlong aul_timeout);// Create a mailslot
//
// it can only be a local mailslot

ulong lul_ret, lul_error

as_path = "\\.\mailslot\" + as_path

is_fullpath = as_path
iul_max_size = aul_maxsize

lul_ret = CreateMailslot(as_path, aul_maxsize, aul_timeout, 0)
if lul_ret = invalid_handle_value then
	lul_error = GetLastError( )
end if

return lul_ret

end function

on nv_mailslot.create
call super::create
TriggerEvent( this, "constructor" )
end on

on nv_mailslot.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on

