;求1+2+3...+100=

jmp near start

color db 0x04
message db "1+2+3+...+100="
message_end:
save db 0,0,0,0,0

start:
    mov ax,0xb8f0   ;显示缓冲区
    mov es,ax
    mov ax,0x07c0   ;字符
    mov ds,ax
    xor ax,ax       ;初始化栈段
    mov ss,ax       
    mov sp,0x40


;字符串压栈
    mov si,message
    mov cx,message_end-message
    xor di,di
show_message:
    mov al,[ds:si]
    mov ah,[color]
    mov [es:di],ax
    inc si
    add di,2
    loop show_message

 ;计算
    mov cx,0
    xor ax,ax
calc:   
    inc cx   
    add ax,cx
    cmp cx,100
    jl calc

;转换可视化字符
    mov bx,10
to_ascii:
    xor dx,dx
    div bx
    add dl,0x30
    mov dh,[color]
    push dx
    test ax,ax
    jnz to_ascii

;输出到屏幕
show:
    pop ax
    mov ah,[color]
    mov [es:di],ax
    add di,2
    cmp sp,0x40
    je end
    loop show

end:

jmp $


times 510-($-$$) db 0
                 db 0x55,0xaa