;; Задачи для практики. Твой код — в местах, помеченных TODO.
;; Собрать и проверить: make && ./test

%include "x86inc.asm"

SECTION_RODATA

; TODO(задача 3): маска для pshufb — перестановка RGBA → BGRA.
; Каждый выходной байт = индекс входного байта. Пиксель 0 занимает байты 0..3 (R,G,B,A).
; Сейчас маска тождественная — замени индексы.
bgra_shuffle: db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

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
INIT_XMM sse2
cglobal invert, 2, 2, 2, src, width
    ; TODO: подготовка (сдвиг указателя, neg)
    ; TODO: цикл — load, инверсия, store, add/jl
    RET

;-----------------------------------------------------------------------------
; ЗАДАЧА 2: яркость с насыщением
; static void brighten_sat(uint8_t *src, ptrdiff_t width)
; Каждый байт: src[i] = min(src[i] + 40, 255). Обычный paddb даст
; переполнение (250+40=34 — тёмные пятна на светлом). Найди в справочнике
; https://www.felixcloutier.com/x86/ инструкцию НАСЫЩЕННОГО сложения байтов
; (packed add unsigned saturate) — и построй цикл вокруг неё.
; Константу [40 ×16] объяви в SECTION_RODATA: times 16 db 40
;-----------------------------------------------------------------------------
SECTION_RODATA

saturation_numbers: times 16 db 40

SECTION .text

INIT_XMM sse2
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

;-----------------------------------------------------------------------------
; ЗАДАЧА 3: RGBA → BGRA (обмен каналов R и B)
; static void rgba_to_bgra(uint8_t *src, ptrdiff_t width)
; Классика: OpenCV хранит BGR, почти всё остальное — RGB. 16 байт = ровно
; 4 пикселя RGBA. Одна pshufb с правильной маской переставляет каналы
; всех четырёх пикселей разом. Исправь маску bgra_shuffle вверху файла
; (индексы: для каждого выходного байта — откуда взять входной) и напиши цикл.
; Внимание: pshufb — это SSSE3, не SSE2. Что поменять в INIT-строке/cglobal?
;-----------------------------------------------------------------------------
INIT_XMM sse2
cglobal rgba_to_bgra, 2, 2, 2, src, width
    ; TODO
    RET
