// Обвязка: сверяет твой ассемблер с эталоном на C и меряет скорость.
// Собрать: make   Запустить: ./test
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <time.h>

#define N (1 << 20)  /* 1 МБ на тест — кратно 16 */
#define RUNS 200

/* cglobal + private_prefix=ex + INIT_XMM sse2 дают символы вида
 * ex_add_values_sse2 — ровно как ff_..._sse2 в FFmpeg: по такому имени
 * рантайм-диспетчер выбирает вариант под CPU.
 * ВНИМАНИЕ: решишь задачу 3 под ssse3 — поправь суффикс здесь. */
void ex_add_values_sse2(uint8_t *src, const uint8_t *src2, ptrdiff_t width);
void ex_invert_sse2(uint8_t *src, ptrdiff_t width);
void ex_brighten_sat_sse2(uint8_t *src, ptrdiff_t width);
void ex_rgba_to_bgra_ssse3(uint8_t *src, ptrdiff_t width);
#define add_values   ex_add_values_sse2
#define invert       ex_invert_sse2
#define brighten_sat ex_brighten_sat_sse2
#define rgba_to_bgra ex_rgba_to_bgra_ssse3

/* ── эталоны на C ── */
static void ref_add_values(uint8_t *a, const uint8_t *b, ptrdiff_t w) {
    for (ptrdiff_t i = 0; i < w; i++) a[i] = (uint8_t)(a[i] + b[i]);
}
static void ref_invert(uint8_t *a, ptrdiff_t w) {
    for (ptrdiff_t i = 0; i < w; i++) a[i] = (uint8_t)(255 - a[i]);
}
static void ref_brighten_sat(uint8_t *a, ptrdiff_t w) {
    for (ptrdiff_t i = 0; i < w; i++) { int v = a[i] + 40; a[i] = v > 255 ? 255 : (uint8_t)v; }
}
static void ref_rgba_to_bgra(uint8_t *a, ptrdiff_t w) {
    for (ptrdiff_t i = 0; i < w; i += 4) { uint8_t t = a[i]; a[i] = a[i + 2]; a[i + 2] = t; }
}

static void fill(uint8_t *p, size_t n, unsigned seed) {
    for (size_t i = 0; i < n; i++) p[i] = (uint8_t)((i * 37 + seed * 101 + 11) & 255);
}

static double now(void) {
    struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

typedef void (*fn1)(uint8_t *, ptrdiff_t);

static int check1(const char *name, fn1 asm_fn, void (*ref_fn)(uint8_t *, ptrdiff_t)) {
    static uint8_t a[N], b[N];
    fill(a, N, 1); memcpy(b, a, N);
    asm_fn(a, N); ref_fn(b, N);
    if (memcmp(a, b, N)) {
        for (size_t i = 0; i < N; i++) if (a[i] != b[i]) {
            printf("  %-14s FAIL: байт %zu: asm=%u, эталон=%u\n", name, i, a[i], b[i]);
            return 1;
        }
    }
    double t0 = now();
    for (int r = 0; r < RUNS; r++) asm_fn(a, N);
    double dt = (now() - t0) / RUNS;
    printf("  %-14s OK    %6.1f мкс/МБ (%5.2f ГБ/с)\n", name, dt * 1e6, N / dt / 1e9);
    return 0;
}

int main(void) {
    int fails = 0;
    printf("проверка (1 МБ, %d прогонов):\n", RUNS);

    /* задача 0 — окружение */
    {
        static uint8_t a[N], b[N], c[N];
        fill(a, N, 1); fill(c, N, 2); memcpy(b, a, N);
        add_values(a, c, N); ref_add_values(b, c, N);
        if (memcmp(a, b, N)) { printf("  %-14s FAIL\n", "add_values"); fails++; }
        else {
            double t0 = now();
            for (int r = 0; r < RUNS; r++) add_values(a, c, N);
            double dt = (now() - t0) / RUNS;
            printf("  %-14s OK    %6.1f мкс/МБ (%5.2f ГБ/с)\n", "add_values", dt * 1e6, N / dt / 1e9);
        }
    }
    fails += check1("invert",       invert,       ref_invert);
    fails += check1("brighten_sat", brighten_sat, ref_brighten_sat);
    fails += check1("rgba_to_bgra", rgba_to_bgra, ref_rgba_to_bgra);

    printf(fails ? "\n%d задач(и) ещё не решены\n" : "\nвсё решено — красавчик\n", fails);
    return fails;
}
