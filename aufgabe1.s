.text/* Specify that code goes in text segment */
.code 32 /* Select ARM instruction set */


.global _startup/* Specify global symbol */ 
_startup:

mystart:
    mov r0, #25
    mov r1, #204
    add r2, r0, r1

stop:
.end