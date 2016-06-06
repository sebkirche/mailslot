MailSlot
========

Several projects to use the Win32 Mailslot communication channel.

* **jnaMailslot** contains a java mailslot jna wrapper and a sample console application that perform both a client and server test with a mailslot \\.\mailslot\javaslot

* **pbMailslot** contains a Powerbuilder Classic interface to the Win32 Mailslots and a sample application. If you want to test it with the java implementation, you need to replace the default name 'slotpath' by 'javaslot' which is the slot name used by the java testing class.
