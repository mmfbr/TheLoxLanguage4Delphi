// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Consts;

{$I LoxLanguage.VirtualMachine.inc}

interface

const
  UINT8_COUNT = High(UINT8) + 1;
  UINT8_MAX = High(UINT8) + 1;
  UINT16_MAX  = High(UINT16) + 1;
  CLOCKS_PER_SEC  = 1000;
  STACK_MAX = 256;
  FRAMES_MAX = 64;
  GC_HEAP_GROW_FACTOR = 2;


implementation

end.
