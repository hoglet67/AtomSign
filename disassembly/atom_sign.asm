; Memory locations
l0000           = &0000
l0001           = &0001
l0002           = &0002
l0003           = &0003
l0004           = &0004
l0006           = &0006
l0007           = &0007
l0008           = &0008
l0009           = &0009
ptrleft         = &0080
ptrcursor       = &0082
ptrtmp          = &0084
offset          = &0086
offset_tmp      = &0087
tempa           = &0088
cursor_mask     = &00e1
capslock_flag   = &00e7
l0100           = &0100
l0101           = &0101
l0102           = &0102
wrchv           = &0208
rdchv           = &020a
l8000           = &8000
l8100           = &8100
buffer          = &8200
buffer_end      = &83f9
via_porta       = &b801
via_ddra        = &b803
atom_nvwrch     = &fe55
atom_nvrdch     = &fe94
ossave          = &ffdd
osload          = &ffe0
osrdch          = &ffe3
osasci          = &ffe9
oscrlf          = &ffed
oswrch          = &fff4
oscli           = &fff7

    org &a000

.start
.pydis_start
    lda #>atom_nvwrch
    sta wrchv+1
    lda #<atom_nvwrch
    sta wrchv
    jsr buffer_clear
    jmp intialize_via

.handle_03_clear
    jsr send_to_message_board
    jsr buffer_clear
.handle_ignore_01_16_18_19_1a
    rts

.handle_default
    jsr send_to_message_board
    tax
    lda buffer_end
    beq ca025
.output_bell
    lda #7
    jmp oswrch

.ca025
    jsr buffer_insert_char
    jsr buffer_display
    jsr buffer_inc_cursor
    jmp delete_char_on_screen

.handle_04_delete
    jsr send_to_message_board
    jsr buffer_dec_cursor
    bcc ca05f
    lda buffer
    beq ca068
    ldx #ptrcursor
    jsr zpx_dec16
    jsr buffer_delete_char
    ldx #ptrcursor
    jsr zpx_inc16
    ldy #1
    lda buffer
    beq ca06b
    cmp #&1a
    bcs ca057
    iny
.ca057
    sty offset
    jsr buffer_display
    jmp delete_char_on_screen

.ca05f
    jsr buffer_delete_char
    jsr buffer_display
    jmp delete_char_on_screen

.ca068
    jsr output_bell
.ca06b
    jmp buffer_clear

.handle_09_load
    jsr send_to_message_board
    jmp do_load_or_send

.handle_0f_save
    jsr send_to_message_board
    jmp do_save

.handle_08_1d_5d_right
    jsr send_to_message_board
    jsr delete_char_on_screen
    jsr buffer_inc_cursor
    jmp delete_char_on_screen

.handle_15_5b_left
    jsr send_to_message_board
    jsr delete_char_on_screen
    jsr buffer_dec_cursor
    jmp delete_char_on_screen

.handle_0c_toggle_caps
    lda capslock_flag
    eor #&60 ; '`'
    sta capslock_flag
    tya
.handle_11
    jmp send_to_message_board

.handle_0e_search
    jsr send_to_message_board
    jsr enter_search_string
    bcs ca0a7
.ca0a4
    jsr do_search
.ca0a7
    jsr screen_clear
    jsr buffer_display
    jmp delete_char_on_screen

.buffer_clear
    lda #&0c
    jsr oswrch
    lda #>buffer
    sta ptrleft+1
    sta ptrcursor+1
    ldy #0
    sty offset
    sty ptrleft
    sty ptrcursor
    sty cursor_mask
    tya
.loop_ca0c6
    sta buffer,y
    sta buffer+&100,y
    iny
    bne loop_ca0c6
    rts

.screen_clear
    ldy #0
    lda #&20 ; ' '
.loop_ca0d4
    sta l8000,y
    sta l8100,y
    iny
    bne loop_ca0d4
    rts

.read_key_loop
    jsr osrdch
    jsr lookup_key_handler
    bcs ca0f6
    sta ptrtmp
    lda #>start
    sta ptrtmp+1
    tya
    jsr call_key_handler
    jmp read_key_loop

.call_key_handler
    jmp (ptrtmp)

.ca0f6
    jsr handle_default
    jmp read_key_loop

.lookup_key_handler
    cmp #&5b ; '['
    bne ca102
    lda #&15
.ca102
    jsr map_chars_1d5d_to_08
    nop
    nop
    nop
    cmp #&7f
    bne ca10e
    lda #4
.ca10e
    cmp #&1b
    bne ca114
    lda #&12
.ca114
    cmp #&20 ; ' '
    bcc ca119
    rts

.ca119
    tay
    dey
    lda la4ac,y
    iny
    clc
    rts

.buffer_insert_char
    ldy #0
    lda ptrcursor
    sta ptrtmp
    lda ptrcursor+1
    sta ptrtmp+1
.loop_ca12b
    lda (ptrtmp),y
    beq ca13c
    pha
    txa
    sta (ptrtmp),y
    ldx #ptrtmp
    jsr zpx_inc16
    pla
    tax
    bne loop_ca12b
.ca13c
    txa
    sta (ptrtmp),y
    rts

.buffer_delete_char
    ldy #1
    lda ptrcursor
    sta ptrtmp
    lda ptrcursor+1
    sta ptrtmp+1
.loop_ca14a
    lda (ptrtmp),y
    beq ca15a
    dey
    sta (ptrtmp),y
    iny
    inc ptrtmp
    bne ca158
    inc ptrtmp+1
.ca158
    bne loop_ca14a
.ca15a
    dey
    sta (ptrtmp),y
    rts

.buffer_display
    ldy #0
    ldx #0
    lda buffer
    bne ca16a
    jmp buffer_clear

.ca16a
    lda ptrleft
    sta ptrtmp
    lda ptrleft+1
    sta ptrtmp+1
    lda #&1e
    jsr oswrch
.ca177
    lda (ptrtmp),y
    beq ca19d
    cmp #&1a
    bcs ca18c
    pha
    lda #&ff
    jsr ca1ae
    pla
    inx
    beq ca1aa
    clc
    adc #&40 ; '@'
.ca18c
    jsr ca1ae
    inx
    beq ca1aa
    txa
    pha
    ldx #ptrtmp
    jsr zpx_inc16
    pla
    tax
    bne ca177
.ca19d
    stx offset_tmp
    lda #&20 ; ' '
    jsr ca1ae
    inx
    beq ca1aa
    jmp ca1ae

.ca1aa
    dex
    stx offset_tmp
    rts

.ca1ae
    clc
    adc #&20 ; ' '
    cmp #&80
    bcs ca1b7
    eor #&60 ; '`'
.ca1b7
    sta l8000,x
    rts

.buffer_inc_cursor
    ldy #0
    lda (ptrcursor),y
    beq ca209
    cmp #&1a
    bcs ca1c9
    inc offset
    beq ca1d4
.ca1c9
    inc offset
    beq ca1d4
    ldx #ptrcursor
    jsr zpx_inc16
    clc
    rts

.ca1d4
    ldx #ptrleft
    jsr zpx_inc16
    jsr buffer_display
    ldy #0
    lda (ptrtmp),y
    beq ca1ee
    cmp #&1a
    bcs ca1ee
    ldx #ptrleft
    jsr zpx_inc16
    jsr buffer_display
.ca1ee
    lda offset_tmp
    sta offset
    lda ptrtmp
    sta ptrcursor
    lda ptrtmp+1
    sta ptrcursor+1
    clc
    rts

.buffer_dec_cursor
    lda ptrcursor+1
    cmp #>buffer
    bne ca210
    ldy ptrcursor
    beq ca209
    dey
    bne ca210
.ca209
    lda #7
    jsr oswrch
    sec
    rts

.ca210
    ldx #ptrcursor
    jsr zpx_dec16
    ldy #0
    lda (ptrcursor),y
    cmp #&1a
    bcs ca21f
    dec offset
.ca21f
    dec offset
    bne ca237
    inc offset
    ldx #ptrleft
    jsr zpx_dec16
    jsr buffer_display
    ldy #0
    lda (ptrleft),y
    cmp #&1a
    bcs ca237
    inc offset
.ca237
    clc
    rts

.delete_char_on_screen
    ldy offset
    beq ca23e
    dey
.ca23e
    lda l8000,y
    eor #&80
    sta l8000,y
    rts

.zpx_inc16
    inc l0000,x
    bne ca24d
    inc l0001,x
.ca24d
    rts

.zpx_dec16
    lda l0000,x
    bne ca254
    dec l0001,x
.ca254
    dec l0000,x
    rts

.send_to_message_board
    jsr map_char_12_to_1b
    eor #&80
    sta via_porta
    nop
    nop
    nop
    eor #&80
    sta via_porta
    nop
    nop
    tya
    pha
    txa
    pha
    ldy #&1e
    ldx #0
.ca271
    dex
    bne ca271
    dey
    bne ca271
    pla
    tax
    pla
    tay
    lda tempa
    rts

.enter_search_string
    ldx #0
.ca280
    jsr print_message_x
    ldx #0
.ca285
    dex
.ca286
    inx
    jsr osrdch
    jsr lookup_key_handler
    bcs ca2ce
    cmp #&17
    beq ca2cd
    tya
    cmp #&0e
    bne ca2a2
.ca298
    jsr send_to_message_board
    lda #0
    sta l0100,x
    clc
    rts

.ca2a2
    cmp #4
    bne ca2c1
.ca2a6
    jsr send_to_message_board
    dex
    bmi ca286
    lda #&7f
    jsr oswrch
    tay
    lda l0100,x
    dex
    cmp #&1a
    bcs ca286
    tya
    jsr oswrch
    jmp ca286

.ca2c1
    cmp #&11
    bne ca285
.ca2c5
    jsr send_to_message_board
    jsr clear_prompt
    sec
    rts

.ca2cd
    tya
.ca2ce
    jsr send_to_message_board
    sta l0100,x
    cmp #&1a
    bcs ca2e2
    pha
    lda #&ff
    jsr oswrch
    pla
    clc
    adc #&40 ; '@'
.ca2e2
    jsr oswrch
    cpx #4
    bcc ca286
    inx
.ca2ea
    jsr osrdch
    jsr lookup_key_handler
    bcs ca2ea
    tya
    cmp #4
    beq ca2a6
    cmp #&11
    beq ca2c5
    cmp #&0e
    beq ca298
    bne ca2ea
.print_message_x
    jsr move_cursor_to_line_10
    lda la4c7,x
    sta ptrtmp
    lda la4d0,x
    sta ptrtmp+1
.loop_ca30e
    lda (ptrtmp),y
    beq ca322
    cmp #&2a ; '*'
    bne ca31c
    jsr oscrlf
    jmp ca31f

.ca31c
    jsr oswrch
.ca31f
    iny
    bne loop_ca30e
.ca322
    rts

.move_cursor_to_line_10
    lda #&1e
    jsr oswrch
    ldy #&0a
    tya
.loop_ca32b
    jsr oswrch
    dey
    bne loop_ca32b
    rts

.do_search
    lda #0
    sta ptrtmp
    lda #>buffer
    sta ptrtmp+1
    ldy #0
.ca33c
    lda l0100,y
    beq ca359
    cmp (ptrtmp),y
    bne ca348
    iny
    bne ca33c
.ca348
    ldx #ptrtmp
    jsr zpx_inc16
    ldy #0
    lda (ptrtmp),y
    bne ca33c
    jsr zpx_dec16
    jsr output_bell
.ca359
    sec
    lda ptrtmp
    sta ptrleft
    adc #0
    sta ptrcursor
    lda ptrtmp+1
    sta ptrleft+1
    adc #0
    sta ptrcursor+1
    ldy #0
    ldx #1
    lda (ptrleft),y
    cmp #&1a
    bcs ca375
    inx
.ca375
    stx offset
    rts

.clear_prompt
    lda #&20 ; ' '
    ldy #0
.loop_ca37c
    sta l8100,y
    iny
    bne loop_ca37c
    rts

.do_load_or_send
    ldx #4
    jsr print_message_x
    ldx #8
    jsr print_message_x
    jsr read_char_test_for_return
    php
    jsr clear_prompt
    plp
    bne do_send
    jsr enter_message_name
    php
    jsr clear_prompt
    plp
    bcs do_send
    jsr do_load
.do_send
    ldx #7
    jsr print_message_x
    ldx #8
    jsr print_message_x
    jsr read_char_test_for_return
    php
    jsr clear_prompt
    plp
    bne ca3d1
    lda #0
    sta ptrtmp
    lda #>buffer
    sta ptrtmp+1
    ldy #0
.loop_ca3c2
    lda (ptrtmp),y
    beq ca3d1
    jsr send_to_message_board
    ldx #ptrtmp
    jsr zpx_inc16
    jmp loop_ca3c2

.ca3d1
    lda #&0d
    jsr send_to_message_board
    jmp send_to_message_board

.read_char_test_for_return
    jsr osrdch
    jsr lookup_key_handler
    bcs ca3e2
    tya
.ca3e2
    jsr send_to_message_board
    cmp #&0d
    rts

.enter_message_name
    ldx #1
    jmp ca280

.do_load
    jsr terminate_filename
    ldx #6
    jsr print_message_x
    dex
    jsr print_message_x
    jsr osrdch
    jsr rdch_skip_next
    jsr clear_prompt
    ldx #3
    jsr print_message_x
    ldx #ptrleft
    lda #0
    sta l0000,x
    sta l0002,x
    lda #1
    sta l0001,x
    lda #>buffer
    sta l0003,x
    sta l0004,x
    jsr osload
.ca41c
    lda #0
    sta ptrleft
    lda #>buffer
    sta ptrleft+1
    lda #0
    sta l0100
    jmp ca0a4

.terminate_filename
    ldy #0
.loop_ca42e
    lda l0100,y
    beq ca436
    iny
    bne loop_ca42e
.ca436
    lda #&0d
    sta l0100,y
    sta l0102
    lda #&4e ; 'N'
    sta l0100
    lda #&2e ; '.'
    sta l0101
    jsr oscli
    rts

.rdch_skip_next
    lda #>null_rdch
    sta rdchv+1
    lda #<null_rdch
    sta rdchv
    rts

.null_rdch
    lda #>atom_nvrdch
    sta rdchv+1
    lda #<atom_nvrdch
    sta rdchv
    rts

.do_save
    jsr enter_message_name
    php
    jsr clear_prompt
    plp
    bcs ca4a9
    jsr terminate_filename
    ldx #2
    jsr print_message_x
    ldx #5
    jsr print_message_x
    jsr osrdch
    jsr rdch_skip_next
    jsr clear_prompt
    ldx #3
    jsr print_message_x
    ldx #ptrleft
    lda #0
    sta l0000,x
    lda #1
    sta l0001,x
    lda #0
    sta l0002,x
    sta l0006,x
    sta l0008,x
    lda #>buffer
    sta l0003,x
    sta l0007,x
    lda #(>buffer) + 2
    sta l0009,x
    jsr ossave
    jsr clear_prompt
.ca4a9
    jmp ca41c

.la4ac
    equb &16, &17, &10, &31, &17, &17, &17, &7a, &6e, &17, &17, &92
    equb &17, &9c, &74, &17, &99, &17, &17, &17, &86, &16, &17, &16
    equb &16, &16, &30
.la4c7
    equb <message0
    equb <message1
    equb <message2
    equb <message3
    equb <message4
    equb <message5
    equb <message6
    equb <message7
    equb <message8
.la4d0
    equb >message0
    equb >message1
    equb >message2
    equb >message3
    equb >message4
    equb >message5
    equb >message6
    equb >message7
    equb >message8
.message0
    equs "SEARCH STRING ? "
    equb 0
.message1
    equs "MESSAGE NAME ? "
    equb 0
.message2
    equs "SWITCH TAPE TO RECORD"
    equb 0
.message3
    equs "PLEASE WAIT"
    equb 0
.message4
    equs "LOAD TAPE ? "
    equb 0
.message5
    equs "*(PRESS SPACE WHEN READY)"
    equb 0
.message6
    equs "SWITCH TAPE TO PLAY"
    equb 0
.message7
    equs "SEND TO SIGN ? "
    equb 0
.message8
    equs "*(RETURN FOR YES)"
    equb 0
.unused1
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0

.intialize_via
    lda #&ff
    sta via_ddra
    jmp read_key_loop

.unused2
    equb 0, 0, 0, 0, 0, 0, 0, 0

.map_char_12_to_1b
    sta tempa
    cmp #&12
    bne ca618
    lda #&1b
.ca618
    sta via_porta
    rts

.unused3
    equb 0, 0, 0, 0

.map_chars_1d5d_to_08
    cmp #&5d ; ']'
    beq ca628
    cmp #&1d
    bne ca62a
.ca628
    lda #8
.ca62a
    rts

.unused4
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    equb 0, 0, 0
    equb &ff,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
    equb   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
.unknown_data
    equb &0a, &20,   0, &10, &40,   2,   0,   0, &ba, &10, &a8, &0a,   0, &88, &80, &2b
    equb &24, &14,   1,   0,   0, &20, &30, &fd, &24,   4, &50,   5, &66, &21,   0, &74
    equb &aa,   0, &20, &90,   0,   0, &81,   0, &0a, &8a, &a6, &8a, &52, &88,   0,   2
    equb &d0,   0,   0,   1,   2,   1, &10, &64, &54,   4,   5,   0, &20, &90, &41, &62
    equb &20,   2, &86,   0, &88, &80,   0,   0, &ca,   0, &80, &82, &0a,   8,   0, &9a
    equb   1,   0,   0, &10,   0, &11,   0, &64,   0,   4, &20,   4, &10, &24,   5, &66
    equb   8,   4, &a0,   2, &80,   0, &80,   0, &a2, &81, &28,   2, &20, &0a, &0f,   1
    equb   0, &10,   0,   0, &10,   0,   0, &76,   6,   0, &40,   5, &14,   0,   4, &67
    equb &aa,   0, &10,   0, &c2,   0, &30, &0a, &60, &89,   8,   1, &88,   8, &14, &2a
    equb   0,   1,   0,   0, &81, &40,   4, &64, &11, &40, &41, &80, &32, &51, &11, &64
    equb &80,   0, &98,   0,   2, &80, &20,   0, &8c,   0, &28, &a0, &0a, &c0, &0c, &a0
    equb   0, &40, &44,   0,   0, &96,   4, &65, &44, &44, &c0, &c5,   0, &40, &54, &66
    equb &0a, &88, &90, &80,   0, &10,   0, &82, &fa, &88, &23, &98, &48, &2a, &22,   8
    equb   0, &40,   0, &60,   0,   1,   0, &64, &1e, &65, &c6, &94, &74, &40,   4, &76
    equb &28, &60,   0,   0, &80,   0, &10, &20, &3a, &3c, &c2, &18, &c0, &88, &38, &0e
    equb   0, &10,   4,   5,   0,   1,   1, &66, &16, &94, &45, &44,   1,   0,   9, &6e
    equb &28, &82,   8,   0, &20,   2, &20, &80,   2, &80,   0, &0a, &46, &e2, &0a, &a8
    equb &14,   4,   3,   0, &44,   0, &40, &e5, &11,   6, &45, &55, &20, &54,   4, &64
    equb   2,   0,   0,   8,   8, &0a, &20, &42, &0a, &28, &22, &80, &82, &a8,   0,   0
    equb &41, &44,   0,   0,   4, &10,   0, &60,   0, &24, &11, &45, &25, &21, &95, &66
    equb &20,   0,   0, &98,   0,   0, &20, &88, &9a, &2c, &aa,   8, &38,   2, &20, &20
    equb   4,   1, &40,   0, &58,   1,   5, &66,   2, &13, &24, &50, &16, &24,   7, &66
    equb &0a,   0, &90, &10,   0, &20, &82, &0a, &7a,   2, &11, &22, &20, &22, &88,   0
    equb &14, &a0,   4,   1,   0,   2,   0, &64,   7, &45, &65, &41, &c4, &55,   5, &66
    equb &a2,   0, &22, &89,   4, &10, &30,   8, &28, &80, &9a, &28, &8a, &9a,   2, &80
    equb   1, &40,   4,   0,   0,   1, &20, &64, &35, &11, &c0,   4, &10, &40, &a1, &67
    equb   2, &8a,   0,   2, &22,   0,   0,   2, &0a, &c2, &0c, &40,   1, &2a, &e2, &82
    equb   1,   0,   4, &40, &20,   1,   0, &64,   5, &50,   5,   8, &85, &81, &40, &64
    equb &28,   0,   0, &20,   0, &22,   0, &a0, &4a, &82,   6, &62, &a0, &2c, &a0, &1b
    equb   1,   0,   1, &40, &40,   0,   5, &64,   5, &40, &45, &90, &50, &10,   1, &67
    equb &42, &0a,   0,   0,   0,   2,   0,   8,   8, &2a,   0, &0b, &12, &82, &18, &8a
    equb &40, &15,   1,   0,   0,   0,   4, &64, &45,   5,   5, &45,   1,   0,   5, &66
    equb &20, &20,   0,   8,   0,   0,   2,   0, &2f, &0a,   0,   2, &18,   0, &82, &60
    equb &80, &60, &42, &50,   1,   0, &10, &64,   1, &90, &11, &44,   4, &20, &2a, &64
    equb &0a,   0,   2,   0,   0,   0, &10,   0, &43, &a8, &8e, &83, &29, &ca, &0a,   0
    equb &40,   4, &90,   4,   0,   1,   0, &74, &10, &c0, &15, &59, &85,   4,   1, &65
    equb &8a, &20, &20,   0, &32, &1a,   0,   0, &0a,   1, &12, &18,   2,   8, &a2, &c2
    equb &44, &11, &14,   4, &55, &50, &40, &64, &25, &45, &15, &40, &b1,   1, &74, &6d
    equb &72,   8, &20,   0, &20,   8, &80, &0a, &29, &0a, &40, &ae, &22, &22, &62,   2
    equb &14, &80,   0,   0,   0,   5, &10, &64,   8, &45, &84, &c4, &20, &84, &65, &66
    equb &ca, &28,   0,   8,   0,   2,   0,   0, &5a, &8a, &0a, &70, &48, &88, &0a, &0a
    equb   0,   4,   0,   4, &80,   0,   0, &60, &44, &44,   1, &14, &10, &8d, &24, &e4
    equb   8,   8, &a8, &10,   0, &80,   8,   0, &3e,   0,   2, &82,   9, &82, &2e, &b8
    equb &14, &45,   0,   5,   1, &50,   0, &64,   1,   1, &65,   1,   1, &14, &41, &67
    equb &a2,   0, &40, &0d,   0, &10,   0, &80, &2b, &8a,   8, &2a,   6, &82, &16,   0
    equb &50,   0,   1,   0,   0, &44,   0, &64,   1, &c4,   5,   5,   5, &40, &45, &66
    equb &4c,   0,   0, &40,   2,   2, &20,   2, &19, &ab, &26, &b8, &22,   2, &2a, &62
    equb   0,   0,   0,   0,   5,   0,   0, &74,   0,   8, &97, &48,   5, &2e,   1, &64
    equb &28, &12,   0,   0,   0, &80, &88, &28, &db, &80, &0a, &3b,   8,   8, &82,   2
    equb &44, &45,   1, &81,   5,   0, &41, &65,   1,   4,   4, &85, &21, &44,   1, &f6
    equb &1a, &0a,   2,   0,   0, &42,   0,   8, &72, &80, &8b,   2,   8, &18, &83, &38
    equb   5, &10, &84,   1,   0,   4, &10, &64, &84,   4, &44, &44, &14,   4, &37, &76
    equb &a2, &40,   2,   2, &0a,   0, &42,   0, &8b,   0, &82, &9c, &82,   9, &1a,   9
    equb   4, &80, &41, &41,   0,   0,   0, &66, &c0, &a4, &85, &14,   5,   5, &44, &e5
    equb &28,   8,   0,   8,   0,   2,   2,   0, &4a, &0a,   8, &19, &68, &0e, &0c, &0a
    equb   0,   4,   0, &40, &84,   0,   0, &64, &84,   0, &10, &1c,   4, &44, &15, &66
    equb   8, &80, &9a,   8,   8,   8, &22, &40, &2e, &22, &e0, &50, &22,   2, &a8, &9a
    equb   0, &24,   4, &21, &41, &20,   1, &64,   3,   0,   1, &11, &51, &8c, &4c, &64
    equb &28, &92, &80,   0, &10,   0,   2, &20, &22, &8a, &98, &0a, &0a,   1,   2,   2
    equb   0, &30,   0,   0, &44,   0, &21, &64, &45, &17,   1,   4, &89, &1d, &4f, &64
    equb &4a,   0,   0, &28,   0, &82, &88,   2, &89, &20, &2a, &18, &0a, &0a, &33, &0b
    equb &58,   4, &20,   4, &41,   5,   1, &66, &0c, &4d,   1, &91,   0, &75,   9, &66
    equb &2a,   0,   0,   8, &40,   8, &0a,   0, &8a,   0, &0a,   0, &0a, &60, &90, &0a
    equb   0, &80, &10,   1,   1,   0,   1, &64, &45, &35, &94, &11,   9,   5, &15, &66
    equb &8c, &ac,   1,   0, &80,   4,   9,   0, &a4, &30, &a4,   4, &81, &a0, &25, &24
    equb   8, &5c, &10, &12, &42, &10,   2, &5f, &42, &5a, &1b, &51, &10, &50, &12, &56
    equb &21, &24,   0, &0c, &80,   0,   5,   5, &23, &a1, &25, &21,   0, &88, &a4, &22
    equb   2, &13,   2, &12, &14, &12,   8, &4e, &32, &28, &49, &50, &52, &48, &56, &66
    equb   0, &85, &a5, &0d, &a0, &25, &85, &81, &f4, &21, &81, &88,   8, &84,   0, &a4
    equb &0a,   2,   8, &11, &42,   0, &48, &46, &42,   8, &50, &58, &40, &12, &40, &66
    equb &af,   8,   4,   1,   1, &a2,   5,   6, &a9, &24, &a0, &20,   4, &24, &a1,   8
    equb   3, &12, &10, &50,   0,   2, &4a, &66, &52, &50, &10,   8, &50, &12, &42, &66
    equb   6,   5, &80, &20, &28,   0, &0c,   1, &ac, &a0, &81,   0, &a0, &25, &a1, &31
    equb &44, &5a, &0a,   0,   3, &50,   4, &46, &10, &51, &40, &60,   6, &50, &58, &66
    equb &28, &20, &88,   0,   0, &a0, &0d,   1, &e0, &80, &80,   1, &86, &80, &a0, &20
    equb &48, &0f,   3,   2,   8,   2, &12, &6e, &50, &48, &19, &50, &58, &4f, &58, &66
    equb &0d,   0,   1, &80, &20,   8, &84,   4, &26, &b0, &8a, &80, &60, &81, &20,   0
    equb   3,   8, &0a, &40,   0,   1, &42, &67,   0, &7d, &53, &80,   0,   3, &1a, &66
    equb &85, &25, &21,   0,   0, &85,   4, &a9, &84,   4, &22, &a0, &e0, &80, &a0, &40
    equb   0,   8,   2, &0b, &14,   3,   0, &46, &50, &32, &10,   8, &58, &48,   0, &66
    equb &25, &0c,   0, &85, &21,   4,   3,   1, &e0, &a0, &80, &90, &24,   8, &e9, &0e
    equb &53, &4a, &52,   8, &4a, &10, &44, &46, &10, &10,   0, &d2, &50, &18, &5e, &56
    equb &2d, &a4, &25, &cc,   4, &85, &8c,   0, &6d,   1, &10, &24,   2, &20, &8d,   2
    equb &40,   1,   0,   8,   2,   6, &12, &4e, &40, &52, &42, &18,   0, &4b, &50, &76
    equb &2b,   0,   5,   1, &22, &29, &81, &26, &64, &a0, &24, &a4, &8c,   4, &80, &a1
    equb &40, &72, &36, &0e, &58,   8, &10, &46,   6, &50, &4d, &12, &18, &52, &48, &56
    equb &a5, &22,   0,   0,   8,   5, &a1,   4, &24, &20, &e4, &e0, &b4,   0, &24, &a0
    equb &10, &30, &40,   8,   8,   2, &12, &46, &c0,   0, &58, &c2,   0, &40,   8, &76
    equb &a5,   9, &25, &80,   4,   1,   1,   4, &2c, &41, &8d, &84, &a0, &a0, &b4, &84
    equb &40, &14, &10, &1c, &10,   1,   1, &46, &80, &da, &45, &50, &58, &10, &12, &66
    equb   4,   0,   0, &0c, &20,   4, &0c, &80, &a5, &84, &80, &80, &a4, &20, &80, &a1
    equb &4c, &40, &4a, &0a,   2, &52,   1, &26, &40, &e8, &5c, &52, &4b, &52, &52, &46
    equb &a5, &29,   4, &44,   5, &20, &0c, &20, &a2, &80, &e0, &81, &ad, &49, &b5, &a0
    equb &5a, &40,   3, &1a, &16, &40, &14, &56, &90, &60, &10, &40, &41, &51, &14, &56
    equb &20,   0, &0c,   5, &20, &24,   1,   4, &ae,   8, &a4, &24, &c3, &20, &a1, &a1
    equb   2, &4c, &42,   2,   6, &c0,   8, &46, &40, &10, &40, &58, &40, &52, &60, &46
    equb &a8, &24, &a2, &85,   0, &25, &21, &21, &b4, &80,   0, &a0, &54, &a0, &25,   2
    equb &44, &0a, &18,   2, &18, &12, &15, &46,   2, &50, &40, &90, &48,   8, &42, &66
    equb   6, &a0, &80,   4, &21, &22, &a8, &81, &a8, &a5, &a0,   5, &a0,   1, &a0, &20
    equb   0,   5,   2, &0b, &40, &42, &40, &66, &40, &1a, &46, &34, &50, &54,   5, &66
    equb &2c, &24, &a6, &2c, &0c, &80,   4, &80, &c0, &61, &b6, &90, &24,   4, &87,   5
    equb &50, &42, &50,   2,   0,   0,   2, &46, &42, &40, &5c, &50, &50, &68, &32, &66
    equb &0d,   9,   0, &84,   0, &a0, &a0,   0, &a1, &a0, &10, &24, &a0, &a4, &90, &24
    equb &41, &4a,   0, &0d,   8,   3, &47, &46, &40, &52,   0, &50, &12, &16, &50, &ce
    equb &88, &21, &a2, &81, &24,   1,   0,   0, &e4, &a4, &20, &80, &25, &81,   0, &a0
    equb   8, &48,   0, &59, &58, &0a, &16, &4f,   0, &10, &12, &92, &92, &58, &52, &56
    equb &2f, &21, &0d,   8, &21, &26,   7,   0, &20, &81, &40, &20, &84,   3,   0, &a8
    equb &10,   2,   2, &0a, &0c, &5c, &40, &46, &43, &18, &12, &50, &12, &40,   2, &76
    equb &0d,   2, &80,   8, &85,   7, &a4,   4, &a5, &c0, &a0, &a0, &a0, &88, &80, &80
    equb   0, &10,   0,   4, &1e, &40, &0c, &46, &50, &12, &5c,   0, &10,   9, &52, &76
    equb &0d, &80, &82,   4, &81, &b0, &25, &21, &c1, &e0, &a4, &a0, &a9, &30,   0, &a6
    equb &10,   0, &0d,   1, &12, &0c, &0b, &46, &44, &72, &41, &50, &10, &50, &10, &66
    equb &84, &0c, &85,   4, &20,   0,   0, &22, &b4, &84, &20, &20, &20, &c1, &10, &60
    equb &42, &1a,   0, &58, &0f,   0, &11, &4e,   0, &59, &59, &40, &4a,   4, &50, &66
    equb &a5,   4, &28, &0d, &21,   0,   1,   4, &a0, &10, &e0, &20, &a8, &80,   5, &88
    equb   3,   3, &53, &1c,   6,   0,   0, &56,   2, &92, &50, &19, &18, &40, &52, &46
    equb   0, &23, &22,   0, &84, &a2,   5, &80, &60, &a4, &a1, &a2, &80, &84, &a1, &28
    equb   0, &58, &80, &48,   8,   0, &12, &ce, &48, &18,   4, &10, &40, &50, &5c, &56
    equb &86,   1, &25, &60,   0,   4,   0,   0, &a5,   1, &80,   0,   4, &20,   1, &29
    equb   9,   0, &18,   8, &10, &5a, &1a, &46, &40, &48, &89, &1a, &c2, &52, &16, &7e
    equb   0,   8,   0,   4,   0, &21,   0, &a5, &a1,   1, &81, &8c, &20, &24, &90, &c0
    equb &4a, &44, &0e, &40,   8,   0, &42, &66,   0, &40, &50, &5c,   0,   0, &44, &7e
    equb &ae,   4,   5,   1, &20,   0, &21, &28, &54,   0, &86, &21, &28, &40,   0, &a0
    equb &0a, &12, &1e,   0,   2, &12, &54, &47, &52, &10, &40,   8, &52, &1e, &53, &76
    equb &2b, &85,   4,   1,   0,   1,   8, &a0, &a0, &8d, &20, &c0, &24, &a0,   9, &65
    equb   8,   0,   9, &18,   0, &12,   2, &66, &70, &18, &10, &56, &40, &58, &74, &f6
    equb &25, &81,   0, &2c, &80, &88, &0a, &80, &a1, &24, &21, &80, &84, &85,   0, &98
    equb &1b, &18, &1a, &12,   8, &0e,   0,   6, &51, &28, &12, &50, &40,   3, &84, &76
.pydis_end

; Automatically generated labels:
;     ca025
;     ca057
;     ca05f
;     ca068
;     ca06b
;     ca0a4
;     ca0a7
;     ca0f6
;     ca102
;     ca10e
;     ca114
;     ca119
;     ca13c
;     ca158
;     ca15a
;     ca16a
;     ca177
;     ca18c
;     ca19d
;     ca1aa
;     ca1ae
;     ca1b7
;     ca1c9
;     ca1d4
;     ca1ee
;     ca209
;     ca210
;     ca21f
;     ca237
;     ca23e
;     ca24d
;     ca254
;     ca271
;     ca280
;     ca285
;     ca286
;     ca298
;     ca2a2
;     ca2a6
;     ca2c1
;     ca2c5
;     ca2cd
;     ca2ce
;     ca2e2
;     ca2ea
;     ca31c
;     ca31f
;     ca322
;     ca33c
;     ca348
;     ca359
;     ca375
;     ca3d1
;     ca3e2
;     ca41c
;     ca436
;     ca4a9
;     ca618
;     ca628
;     ca62a
;     l0000
;     l0001
;     l0002
;     l0003
;     l0004
;     l0006
;     l0007
;     l0008
;     l0009
;     l0100
;     l0101
;     l0102
;     l8000
;     l8100
;     la4ac
;     la4c7
;     la4d0
;     loop_ca0c6
;     loop_ca0d4
;     loop_ca12b
;     loop_ca14a
;     loop_ca30e
;     loop_ca32b
;     loop_ca37c
;     loop_ca3c2
;     loop_ca42e
    assert (>buffer) + 2 == &84
    assert <atom_nvrdch == &94
    assert <atom_nvwrch == &55
    assert <message0 == &d9
    assert <message1 == &ea
    assert <message2 == &fa
    assert <message3 == &10
    assert <message4 == &1c
    assert <message5 == &29
    assert <message6 == &43
    assert <message7 == &57
    assert <message8 == &67
    assert <null_rdch == &57
    assert >atom_nvrdch == &fe
    assert >atom_nvwrch == &fe
    assert >buffer == &82
    assert >message0 == &a4
    assert >message1 == &a4
    assert >message2 == &a4
    assert >message3 == &a5
    assert >message4 == &a5
    assert >message5 == &a5
    assert >message6 == &a5
    assert >message7 == &a5
    assert >message8 == &a5
    assert >null_rdch == &a4
    assert >start == &a0
    assert ptrcursor == &82
    assert ptrleft == &80
    assert ptrtmp == &84

save pydis_start, pydis_end
