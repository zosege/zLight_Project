unit uConst;

interface

uses Graphics;

const
  TotalModeIcons = 29;

  LEDPreviewSize = 30;

  M = 1;
  LightsPerM = 60;

  DefLightsLeft     = Round(0.661*M*LightsPerM);
  DefLightsTop      = Round(1.029*M*LightsPerM);
  DefLightsRight    = DefLightsLeft;
  DefLightsBottom   = DefLightsTop;

  DefLightsAll = DefLightsLeft + DefLightsTop + DefLightsRight + DefLightsBottom;

  DIR_DOWN       = 0;
  DIR_UP         = 1;
  DIR_RIGHT      = 2;
  DIR_LEFT       = 3;

  SPEED_SLOW     = 0;
  SPEED_MID      = 1;
  SPEED_HIGH     = 2;

  modAlt   = $01;
  modCtrl  = $02;
  modShift = $04;
  modWin   = $08;

var
  Lights: PColor;

  LightsLeft  : Integer = DefLightsLeft  ;
  LightsTop   : Integer = DefLightsTop   ;
  LightsRight : Integer = DefLightsRight ;
  LightsBottom: Integer = DefLightsBottom;
  LightsAll   : Integer = DefLightsAll   ;

  gammaR: Array [0..255] of Byte=(
    $00, $00, $00,$00,$00,$00,$00,$00,
    $00, $00, $00,$00,$00,$00,$00,$01,
    $01, $01, $01,$01,$01,$01,$01,$01,
    $01, $02, $02,$02,$02,$02,$02,$02,
    $03, $03, $03,$03,$03,$04,$04,$04,
    $04, $05, $05,$05,$05,$06,$06,$06,
    $06, $07, $07,$07,$08,$08,$08,$09,
    $09, $09, $0A,$0A,$0B,$0B,$0B,$0C,
    $0C, $0D, $0D,$0D,$0E,$0E,$0F,$0F,
    $10, $10, $11,$11,$12,$12,$13,$13,
    $14, $14, $15,$16,$16,$17,$17,$18,
    $19, $19, $1A,$1A,$1B,$1C,$1C,$1D,
    $1E, $1E, $1F,$20,$21,$21,$22,$23,
    $23, $24, $25,$26,$27,$27,$28,$29,
    $2A, $2B, $2B,$2C,$2D,$2E,$2F,$30,
    $31, $31, $32,$33,$34,$35,$36,$37,
    $38, $39, $3A,$3B,$3C,$3D,$3E,$3F,
    $40, $41, $42,$43,$44,$45,$46,$47,
    $49, $4A, $4B,$4C,$4D,$4E,$4F,$51,
    $52, $53, $54,$55,$57,$58,$59,$5A,
    $5B, $5D, $5E,$5F,$61,$62,$63,$64,
    $66, $67, $69,$6A,$6B,$6D,$6E,$6F,
    $71, $72, $74,$75,$77,$78,$79,$7B,
    $7C, $7E, $7F,$81,$82,$84,$85,$87,
    $89, $8A, $8C,$8D,$8F,$91,$92,$94,
    $95, $97, $99,$9A,$9C,$9E,$9F,$A1,
    $A3, $A5, $A6,$A8,$AA,$AC,$AD,$AF,
    $B1, $B3, $B5,$B6,$B8,$BA,$BC,$BE,
    $C0, $C2, $C4,$C5,$C7,$C9,$CB,$CD,
    $CF, $D1, $D3,$D5,$D7,$D9,$DB,$DD,
    $DF, $E1, $E3,$E5,$E7,$EA,$EC,$EE,
    $F0, $F2, $F4,$F6,$F8,$FB,$FD,$FF
    );

  gammaG: Array [0..255] of Byte=(
    $00, $00, $00,$00,$00,$00,$00,$00,
    $00, $00, $00,$00,$00,$00,$00,$01,
    $01, $01, $01,$01,$01,$01,$01,$01,
    $01, $02, $02,$02,$02,$02,$02,$02,
    $03, $03, $03,$03,$03,$04,$04,$04,
    $04, $05, $05,$05,$05,$06,$06,$06,
    $06, $07, $07,$07,$08,$08,$08,$09,
    $09, $09, $0A,$0A,$0B,$0B,$0B,$0C,
    $0C, $0D, $0D,$0D,$0E,$0E,$0F,$0F,
    $10, $10, $11,$11,$12,$12,$13,$13,
    $14, $14, $15,$16,$16,$17,$17,$18,
    $19, $19, $1A,$1A,$1B,$1C,$1C,$1D,
    $1E, $1E, $1F,$20,$21,$21,$22,$23,
    $23, $24, $25,$26,$27,$27,$28,$29,
    $2A, $2B, $2B,$2C,$2D,$2E,$2F,$30,
    $31, $31, $32,$33,$34,$35,$36,$37,
    $38, $39, $3A,$3B,$3C,$3D,$3E,$3F,
    $40, $41, $42,$43,$44,$45,$46,$47,
    $49, $4A, $4B,$4C,$4D,$4E,$4F,$51,
    $52, $53, $54,$55,$57,$58,$59,$5A,
    $5B, $5D, $5E,$5F,$61,$62,$63,$64,
    $66, $67, $69,$6A,$6B,$6D,$6E,$6F,
    $71, $72, $74,$75,$77,$78,$79,$7B,
    $7C, $7E, $7F,$81,$82,$84,$85,$87,
    $89, $8A, $8C,$8D,$8F,$91,$92,$94,
    $95, $97, $99,$9A,$9C,$9E,$9F,$A1,
    $A3, $A5, $A6,$A8,$AA,$AC,$AD,$AF,
    $B1, $B3, $B5,$B6,$B8,$BA,$BC,$BE,
    $C0, $C2, $C4,$C5,$C7,$C9,$CB,$CD,
    $CF, $D1, $D3,$D5,$D7,$D9,$DB,$DD,
    $DF, $E1, $E3,$E5,$E7,$EA,$EC,$EE,
    $F0, $F2, $F4,$F6,$F8,$FB,$FD,$FF
    );

  gammaB: Array [0..255] of Byte=(
    $00, $00, $00,$00,$00,$00,$00,$00,
    $00, $00, $00,$00,$00,$00,$00,$01,
    $01, $01, $01,$01,$01,$01,$01,$01,
    $01, $02, $02,$02,$02,$02,$02,$02,
    $03, $03, $03,$03,$03,$04,$04,$04,
    $04, $05, $05,$05,$05,$06,$06,$06,
    $06, $07, $07,$07,$08,$08,$08,$09,
    $09, $09, $0A,$0A,$0B,$0B,$0B,$0C,
    $0C, $0D, $0D,$0D,$0E,$0E,$0F,$0F,
    $10, $10, $11,$11,$12,$12,$13,$13,
    $14, $14, $15,$16,$16,$17,$17,$18,
    $19, $19, $1A,$1A,$1B,$1C,$1C,$1D,
    $1E, $1E, $1F,$20,$21,$21,$22,$23,
    $23, $24, $25,$26,$27,$27,$28,$29,
    $2A, $2B, $2B,$2C,$2D,$2E,$2F,$30,
    $31, $31, $32,$33,$34,$35,$36,$37,
    $38, $39, $3A,$3B,$3C,$3D,$3E,$3F,
    $40, $41, $42,$43,$44,$45,$46,$47,
    $49, $4A, $4B,$4C,$4D,$4E,$4F,$51,
    $52, $53, $54,$55,$57,$58,$59,$5A,
    $5B, $5D, $5E,$5F,$61,$62,$63,$64,
    $66, $67, $69,$6A,$6B,$6D,$6E,$6F,
    $71, $72, $74,$75,$77,$78,$79,$7B,
    $7C, $7E, $7F,$81,$82,$84,$85,$87,
    $89, $8A, $8C,$8D,$8F,$91,$92,$94,
    $95, $97, $99,$9A,$9C,$9E,$9F,$A1,
    $A3, $A5, $A6,$A8,$AA,$AC,$AD,$AF,
    $B1, $B3, $B5,$B6,$B8,$BA,$BC,$BE,
    $C0, $C2, $C4,$C5,$C7,$C9,$CB,$CD,
    $CF, $D1, $D3,$D5,$D7,$D9,$DB,$DD,
    $DF, $E1, $E3,$E5,$E7,$EA,$EC,$EE,
    $F0, $F2, $F4,$F6,$F8,$FB,$FD,$FF
    );

type
  TLinkState = (lsConnected, lsDisconnected, lsReadyToConnect);
  
implementation

end.