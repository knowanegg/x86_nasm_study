;实现将一个标号地址打印出来的程序

jmp near start  ;这里是7c00，必须有指令跳到代码流程，否则会拿前面定义的数据当代码执行

color db 0x04 ;黑底红字
label db 'Lable offset:'
label_end:

start:
mov ax,0xb8f0 ;这里用到es:di但是不能直接赋值，要用ax转
mov es,ax
mov ax,0x07c0
mov ds,ax

mov si,label
xor di,di

mov cx,label_end-label

show_label:
    mov byte al,[ds:si]
    mov byte ah,[color]
    mov [es:di],ax
    inc di
    inc si
    inc di
    loop show_label

mov ax,code_end
mov si,10
add di,4
get_number:   ;计算各个位数
    xor dx,dx  ;这条不能省略，div前dx必须清零！
    div si
    mov bx,dx
    add bl,48
    mov bh,[color]
    mov [es:di],bx
    sub di,2
    test ax,ax
    jnz get_number

jmp $

code_end:

times 512-2-($-$$) db 0
        db 0x55,0xaa