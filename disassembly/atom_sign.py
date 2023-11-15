from commands import *
from acorn import *

config.set_label_references(False);
config.set_hex_dump(False);

# Load the program to be disassembled into the debugger's memory.
load(0xA000, "atom_sign.orig", "6502", "ac70718a5b1dc480a5dfd67e06d0c4ec")


# Standard Aton

label(0x00e1, "cursor_mask")
label(0x00e7, "capslock_flag")

label(0x0208, "wrchv")
expr_label(0x0209, "wrchv+1")
label(0x020a, "rdchv")
expr_label(0x020b, "rdchv+1")
label(0xb801, "via_porta")
label(0xb803, "via_ddra")
label(0xffdd, "ossave")
label(0xffe0, "osload")
label(0xffe3, "osrdch")
label(0xffe9, "osasci")
label(0xffed, "oscrlf")
label(0xfff4, "oswrch")
label(0xfff7, "oscli")

label(0xfe94, "atom_nvrdch");
expr(0xa458, ">atom_nvrdch");
expr(0xa45d, "<atom_nvrdch");

label(0xfe55, "atom_nvwrch");
expr(0xa001, ">atom_nvwrch");
expr(0xa006, "<atom_nvwrch");

# Buffer at &8200-&83f9 (506 characters max message length)

label(0x8200, "buffer");
expr_label(0x8300, "buffer+&100");
label(0x83f9, "buffer_end");

# Zero Page memory

label(0x0080, "ptrleft")
expr_label(0x0081, "ptrleft+1");

label(0x0082, "ptrcursor")
expr_label(0x0083, "ptrcursor+1");

label(0x0084, "ptrtmp")
expr_label(0x0085, "ptrtmp+1");

label(0x0086, "offset")
label(0x0087, "offset_tmp")
label(0x0088, "tempa")

# Expressions for specfic operands to disambiguate
# use of #&80, #&82, #&84

expr(0xa1d5, "ptrleft")
expr(0xa1e7, "ptrleft")
expr(0xa226, "ptrleft")
expr(0xa408, "ptrleft")
expr(0xa488, "ptrleft")

expr(0xa03f, "ptrcursor")
expr(0xa047, "ptrcursor")
expr(0xa1ce, "ptrcursor")
expr(0xa211, "ptrcursor")

expr(0xa134, "ptrtmp")
expr(0xa195, "ptrtmp")
expr(0xa349, "ptrtmp")
expr(0xa3ca, "ptrtmp")

expr(0xa0b6, ">buffer")
expr(0xa1ff, ">buffer")
expr(0xa337, ">buffer")
expr(0xa3bd, ">buffer")
expr(0xa414, ">buffer")
expr(0xa421, ">buffer")
expr(0xa49a, ">buffer")

expr(0xa4a0, "(>buffer) + 2")

expr(0xa0e9, ">start")


# Meaningful Labels, organzied in address order

entry(0xa000, "start")

entry(0xa010, "handle_03_clear")
entry(0xa016, "handle_ignore_01_16_18_19_1a")
entry(0xa017, "handle_default")
label(0xa020, "output_bell")
entry(0xa031, "handle_04_delete")
entry(0xa06e, "handle_09_load")
entry(0xa074, "handle_0f_save")
entry(0xa07a, "handle_08_1d_5d_right")
entry(0xa086, "handle_15_5b_left")
entry(0xa092, "handle_0c_toggle_caps")
entry(0xa099, "handle_11")
entry(0xa09c, "handle_0e_search")
label(0xa0b0, "buffer_clear")
label(0xa0d0, "screen_clear")
label(0xa0de, "read_key_loop")
label(0xa0f3, "call_key_handler")
label(0xa0fc, "lookup_key_handler")

label(0xa121, "buffer_insert_char");
label(0xa140, "buffer_delete_char");
label(0xa15e, "buffer_display");
label(0xa1bb, "buffer_inc_cursor")
label(0xa1fc, "buffer_dec_cursor")

label(0xa239, "delete_char_on_screen")
label(0xa247, "zpx_inc16")
label(0xa24e, "zpx_dec16")
label(0xa257, "send_to_message_board")
label(0xa27e, "enter_search_string")

label(0xa301, "print_message_x")
label(0xa323, "move_cursor_to_line_10")
label(0xa332, "do_search")
label(0xa378, "clear_prompt");
label(0xa383, "do_load_or_send");
label(0xa3a4, "do_send");
label(0xa3d9, "read_char_test_for_return");
label(0xa3e8, "enter_message_name");
label(0xa3ed, "do_load");

label(0xa42c, "terminate_filename")
label(0xa44c, "rdch_skip_next")
expr(0xa44d, ">null_rdch")
expr(0xa452, "<null_rdch")
entry(0xa457, "null_rdch")
label(0xa462, "do_save");

# TODO: Key Handler Table
#
# these should all be derived from labels
#
#.la4ac
#    equb &16, &17, &10, &31, &17, &17, &17, &7a, &6e, &17, &17, &92
#    equb &17, &9c, &74, &17, &99, &17, &17, &17, &86, &16, &17, &16
#    equb &16, &16, &30

# Message Tables

byte(0xa4c7, 9, 1)
byte(0xa4d0, 9, 1)

expr(0xa4c7, "<message0")
expr(0xa4c8, "<message1")
expr(0xa4c9, "<message2")
expr(0xa4ca, "<message3")
expr(0xa4cb, "<message4")
expr(0xa4cc, "<message5")
expr(0xa4cd, "<message6")
expr(0xa4ce, "<message7")
expr(0xa4cf, "<message8")
expr(0xa4d0, ">message0")
expr(0xa4d1, ">message1")
expr(0xa4d2, ">message2")
expr(0xa4d3, ">message3")
expr(0xa4d4, ">message4")
expr(0xa4d5, ">message5")
expr(0xa4d6, ">message6")
expr(0xa4d7, ">message7")
expr(0xa4d8, ">message8")

label(0xa4d9, "message0")
label(0xa4ea, "message1")
label(0xa4fa, "message2")
label(0xa510, "message3")
label(0xa51c, "message4")
label(0xa529, "message5")
label(0xa543, "message6")
label(0xa557, "message7")
label(0xa567, "message8")

label(0xa579, "unused1")
label(0xa600, "intialize_via");
label(0xa608, "unused2")
label(0xa610, "map_char_12_to_1b")
label(0xa61c, "unused3")
label(0xa620, "map_chars_1d5d_to_08")
label(0xa62b, "unused4")
byte(0xa700, 0x100, 16)

label(0xa800, "unknown_data")
byte(0xa800, 0x800, 16)

# Use all the information provided to actually disassemble the program.
go()
