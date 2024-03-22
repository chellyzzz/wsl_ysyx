#include <am.h>
#include <npc.h>

#define KEYDOWN_MASK 0x8000
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  int k = inl(KBD_ADDR);
  kbd->keydown = (k & KEYDOWN_MASK ? true : false);
  kbd->keycode = kbd->keydown ? (k & ~KEYDOWN_MASK) : AM_KEY_NONE;
}
