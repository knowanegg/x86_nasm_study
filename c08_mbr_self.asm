;mbr功能：加载用户程序到内存并完成重定位

app_lba_start equ 100 ;用户程序起始逻辑扇区号,伪指令不占用空间

section mbr align=16 vstart=0x7c00
    ;初始化栈
    mov ax,0    ;这里设置ss为0，sp为0，栈空间实际为0000:ffff开始
    mov ss,ax
    mov sp,ax

    ;初始化段地址指向用户程序加载位置
    mov ax,[user_program_ram_address] ;将用户程序加载到内存的地址低位赋值给ax
    mov dx,[user_program_ram_address+2] ;将用户程序加载到内存的地址高位赋值给dx
    ;将其整体右移4位，即将其转换为段基址
    shr ax,4    
    shl dx,12   
    or ax,dx ;拼接成段基址
    mov ds,ax ;设置数据段指向用户程序加载到内存的地址
    mov es,ax ;设置附加段指向用户程序加载到内存的地址
    push ds   ;保存一下，最后跳转到用户程序要用

    ;以下读取程序的起始部分
    mov si,app_lba_start            ;程序在硬盘上的起始逻辑扇区号 
    xor bx,bx                       ;加载到DS:0x0000处 
    call read_disk_to_ram           ;加载第一个扇区的数据。为什么先加载一个？
                                    ;因为拿到第一个扇区才能拿到程序总大小，才能知道要加载多少个扇区
    mov dx,[2]                      ;程序总大小，单位为字节
    mov ax,[0]                     
    mov bx,512                      ;一个扇区512字节
                                    ;这里为什么不能位移9然后拼接？因为高位可能也是有用的，不像20位地址多出的位数无用
    div bx                          ;dx和ax拼接做除法，商放在ax，余数放在dx
    test ax,ax                      ;如果商0，表示一个扇区都没占满，刚才已经读完了
    jz read_end
    mov cx,ax                       ;多少个扇区循环多少次
    test dx,dx                      ;是否刚好除尽
    jnz no_dec                      ;如果为0，跳过下一条指令
    dec cx                          ;如果余数0，最后要少读一个扇区
    no_dec:
    ;以段去写，每个段写512
    read_loop:
        xor bx,bx                   ;加载到DS:0x0000处 ，每次DS加1即可
        mov ax,ds
        add ax,0x20                 ;这里不是1，是0x20，ds:0x1000，要挪512个，就要挪0x200，放在ds上去掉一个0就是0x20
        mov ds,ax
        inc si                      ;每次向后挪一个扇区
        call read_disk_to_ram
        loop read_loop

    read_end:
    pop ds
    ;读完了，开始在内存中处理用户程序
    ;用户程序加载到内存后，里面的地址要加上内存位置的基地址，叫做重定位
    ;重定位完成后跳转到用户程序入口执行
    mov ax,[0x06]   ;只要修改段基址即可，所以也叫段重定位
    mov dx,[0x08]
    mov bx,0x06
    call calc_segment_base
    mov cx,[0x0a]     ;0x0a dw 存储了重定位表的条目个数
    mov bx,0x0c     ;第一条从0c开始
    relocate_tbl_loop:
        mov ax,[bx]
        mov dx,[bx+2]
        call calc_segment_base
        add bx,4
        loop relocate_tbl_loop
    
    ;重定位结束，跳转到用户程序入口点执行，这里用far清空高速缓冲寄存器
    jmp far [0x04]

    ;段重定位
    ;参数:
    ;   ax:原段基址低位
    ;   dx;原段基址高位
    ;   bx;低位地址
    ;返回：
    ;   ax:重定位后的段基址低位
    ;   dx;重定位后的段基址高位
    calc_segment_base:
        add ax,[cs:user_program_ram_address]        ;要用当前段基址cs，不然默认ds是用户程序0x1000
        adc dx,[cs:user_program_ram_address+2]
                                                    ;写回的是段基址
        shl dx,12
        shr ax,4
        or ax,dx            ;TODO: 这里得到的地址是写到0x06还是0x08？？？

        mov [bx],ax         ;写到06
        ret

    ;将硬盘内容加载到内存
    ;参数： 
    ;   si:程序存储在硬盘的起始逻辑扇区号
    ;   bx:要加载到的内存的起始地址
    read_disk_to_ram:

        push ax
        push bx
        push cx
        push dx

        mov dx,0x1f2                ;8位端口，设置读取的扇区数量
        mov al,1                    ;读取1个扇区
        out dx,al

        mov dx,0x1f3                ;;LBA地址7~0位
        mov ax,si                   
        out dx,al

        xor ax,ax

        mov dx,0x1f4                ;LBA地址15~8位
        out dx,al

        mov dx,0x1f5                ;LBA地址23~16位
        out dx,al

        mov dx,0x1f6                ;LBA地址27~24位，LBA模式，bit7=1
        or al,0xe0                  ;0xe0=1110 0000 ;LBA28模式，主盘
        out dx,al

        mov dx,0x1f7                ;命令寄存器
        mov al,0x20                 ;读取扇区命令
        out dx,al

        .waits:
            in al,dx                ;读取状态寄存器
            and al,0x88
            cmp al,0x08
            jnz .waits                      ;不忙，且硬盘已准备好数据传输 

            mov cx,256              ;读取256个word
            mov dx,0x1f0            ;数据端口

        .read_loop:
            in ax,dx                ;读取数据
            mov [bx],ax             ;写入内存
            add bx,2                ;偏移2个字节
            loop .read_loop         ;循环读取
        
        pop dx
        pop cx
        pop bx 
        pop ax

        ret

user_program_ram_address dd 0x10000 ;用户程序加载到内存的地址

times 510-($-$$) db 0
                 db 0x55,0xaa

