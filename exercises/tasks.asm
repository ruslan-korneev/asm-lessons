;; Задачи для практики. Твой код — в местах, помеченных TODO.
;; Собрать и проверить: make && ./test

%include "x86inc.asm"

SECTION .text

;-----------------------------------------------------------------------------
; ЗАДАЧА 0 (разминка, уже решена — проверка окружения):
; static void add_values(uint8_t *src, const uint8_t *src2, ptrdiff_t width)
; Функция из урока 3 с трюком отрицательного смещения.
;-----------------------------------------------------------------------------
INIT_XMM sse2
cglobal add_values, 3, 3, 2, src, src2, width
    add srcq, widthq
    add src2q, widthq
    neg widthq
.loop:
    movu  m0, [srcq+widthq]
    movu  m1, [src2q+widthq]
    paddb m0, m1
    movu  [srcq+widthq], m0
    add   widthq, mmsize
    jl .loop
    RET

;-----------------------------------------------------------------------------
; ЗАДАЧА 1: негатив изображения
; static void invert(uint8_t *src, ptrdiff_t width)
; Каждый байт: src[i] = 255 - src[i].
; Подсказка: 255 - x == x XOR 255. Заведи в SECTION_RODATA константу
; из 16 байт 0xFF (times 16 db 0xFF) и используй pxor. Либо псевдо-решение
; через psubb из регистра с 255 — как больше нравится.
; Каркас цикла — как в задаче 0, но буфер один.
;-----------------------------------------------------------------------------
SECTION_RODATA

inversion_number: times 16 db 0xFF

SECTION .text

INIT_XMM sse2
cglobal invert, 2, 2, 2, src, width
    ; TODO: подготовка (сдвиг указателя, neg)
    add srcq, widthq            ; add width to src, e.g. 1000+32
    mova m1, [inversion_number] ; load constant
    neg widthq                  ; negative width

    ; TODO: цикл — load, инверсия, store, add/jl
.loop:
    movu m0, [srcq+widthq]       ; load
    pxor m0, m1                  ; inversion
    movu [srcq+widthq], m0       ; store
    add  widthq, mmsize          ; add (e.g. -32+16=-16, -16+16=0)
    jl .loop                     ; jump to next iteration if widthq < 0
    RET                          ; finish

;-----------------------------------------------------------------------------
; ЗАДАЧА 2: яркость с насыщением
; static void brighten_sat(uint8_t *src, ptrdiff_t width)
; Каждый байт: src[i] = min(src[i] + 40, 255). Обычный paddb даст
; переполнение (250+40=34 — тёмные пятна на светлом). Найди в справочнике
; https://www.felixcloutier.com/x86/ инструкцию НАСЫЩЕННОГО сложения байтов
; (packed add unsigned saturate) — и построй цикл вокруг неё.
; Константу [40 ×16] объяви в SECTION_RODATA: times 16 db 40
;-----------------------------------------------------------------------------
SECTION_RODATA 32

saturation_numbers: times 32 db 40

SECTION .text

%macro BRIGHTEN_SAT 0
cglobal brighten_sat, 2, 2, 2, src, width
    ; I guess here is the required instruction (one of them):
    ;  [this signed integers](https://www.felixcloutier.com/x86/paddsb:paddsw)
    ;  [or this unsigned one](https://www.felixcloutier.com/x86/paddusb:paddusw)
    add srcq, widthq
    mova m1, [saturation_numbers]
    neg widthq

.loop:
    movu m0, [srcq+widthq]
    paddusb m0, m1
    movu [srcq+widthq], m0
    add widthq, mmsize
    jl .loop
    RET
%endmacro

INIT_XMM sse2
BRIGHTEN_SAT

INIT_YMM avx2
BRIGHTEN_SAT

;-----------------------------------------------------------------------------
; ЗАДАЧА 3: RGBA → BGRA (обмен каналов R и B)
; static void rgba_to_bgra(uint8_t *src, ptrdiff_t width)
; Классика: OpenCV хранит BGR, почти всё остальное — RGB. 16 байт = ровно
; 4 пикселя RGBA. Одна pshufb с правильной маской переставляет каналы
; всех четырёх пикселей разом. Исправь маску bgra_shuffle вверху файла
; (индексы: для каждого выходного байта — откуда взять входной) и напиши цикл.
; Внимание: pshufb — это SSSE3, не SSE2. Что поменять в INIT-строке/cglobal?
;-----------------------------------------------------------------------------

SECTION_RODATA

bgra_shuffle: db 2, 1, 0, 3, 6, 5, 4, 7, 10, 9, 8, 11, 14, 13, 12, 15

SECTION .text

INIT_XMM ssse3
cglobal rgba_to_bgra, 2, 2, 2, src, width
    add srcq, widthq
    mova m1, [bgra_shuffle]
    neg widthq
.loop:
    movu m0, [srcq+widthq]
    pshufb m0, m1
    movu [srcq+widthq], m0
    add widthq, mmsize
    jl .loop
    RET
