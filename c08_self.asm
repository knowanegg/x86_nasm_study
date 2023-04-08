;用户程序


section header vstart=0
    program_length dd program_end

    code_entry dw start
               dd section.code_1.start
    
    realloc_tbl_len dw (segment_tbl_end-segment_tbl_start)/4
    segment_tbl_start:
        code_1_segment dd section.code_1.start
        code_2_segment dd section.code_2.start
        data_1_segment dd section.data_1.start
        data_2_segment dd section.data_2.start
        stack_segment dd section.stack.start
    segment_tbl_end:

    header_end:

section code_1 align=16 vstart=0
    start:                          ;程序入口
        mov ax,[stack_segment]      ;设置栈段寄存器
        mov ss,ax
        mov sp,stack_end            ;设置栈指针

        mov ax,[data_1_segment]     ;设置数据段寄存器
        mov ds,ax

        call main                   ;调用main函数

        push word [es:code_2_segment]  ;段间调用：先压栈word大小的CS
        push word code_2_entry    ;再压栈word大小的IP

        retf                        ;远返回，pop ip , pop cs
    
    main:
        call cls
        call print_str
        ret

    
    
    print_str:                      ;打印一个字符串，以\0结束
        xor bx,bx
        .get_next_char:             ;遍历字符串中的字符
            mov cl,[bx]
            test cl,cl
            jz .is_null_str
            call print_char
            inc bx
            jmp .get_next_char
        .is_null_str:
            ret

    cls:                       ;清屏
        push ax
        mov ah, 0x00 ; 功能号 0x00 表示设置光标位置
        mov al, 0x02 ; 光标位置设置为 (0,0)
        int 0x10      ; 调用 INT 10h 中断
        pop ax
        ret

    print_char:                     ;打印一个字符，要从当前光标打印，且处理回车换行
                                    ;输入:ax为要打印的ascii
        push ax
        push bx
        push cx
        push dx
        push ds
        push es
        
        .get_cursor:                ;获取当前光标位置
            mov dx,0x3d4
            mov al,0x0e             ;0x0e为光标位置高8位
            out dx,al
            inc dx
            in al,dx                ;al为高8位,取回后放入ah
            mov ah,al

            mov dx,0x3d4
            mov al,0x0f             ;0x0f为光标位置低8位
            out dx,al
            inc dx
            in al,dx                ;al为低8位,取回后放入al

            xor dx,dx
            mov bx,80               ;ax竖列  dx横行
            div bx

        ;判断CRLF
        cmp cl,0x0d
        je .is_0d
        cmp cl,0x0a
        je .is_0a

        ;打印字符
        mov di,0xb800
        mov es,di
        push ax
        mov bx,80
        push dx
        mul bx
        pop dx
        add ax,dx
        shl ax,1
        mov bx,ax
        mov [es:bx],cl              ;写入显示区
        inc dx
        push dx
        jmp .set_cursor
        

        .is_0a:                     ;换行
            inc ax                  ;行号加1
            push ax
            push dx
            jmp .set_cursor
        .is_0d:                     ;回车
            xor dx,dx               ;行号不变，列号清零
            push ax
            push dx
            jmp .set_cursor

        .set_cursor:
            pop cx
            pop ax
            mov bx,80
            mul bx
            add ax,cx
            mov bx,ax

            mov dx,0x3d4
            mov al,0x0e             ;0x0e为光标位置高8位
            out dx,al
            inc dx
            mov al,bh
            out dx,al               ;写入高8位

            mov dx,0x3d4
            mov al,0x0f             ;0x0f为光标位置低8位
            out dx,al
            inc dx
            mov al,bl               ;写入低8位
            out dx,al
        
        pop es
        pop ds
        pop dx
        pop cx
        pop bx
        pop ax

        ret

    continue:
        call print_str
        jmp $


section code_2 align=16 vstart=0
    code_2_entry:
        mov ax,[es:data_2_segment]
        mov ds,ax
        mov ax,[es:code_1_segment]
        push ax
        mov ax,continue
        push ax
        retf

section data_1 align=16 vstart=0
    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0

section data_2 align=16 vstart=0
    msg1 db '  The above contents is written by LeeChung. '
         db '2011-05-06'
         db 0

section stack align=16 vstart=0
    resb 256
    stack_end:

SECTION trail align=16
program_end: