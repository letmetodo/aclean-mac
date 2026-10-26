// ============================================================
//  CleanMateSMCHelper —— AppleSMC 硬件风扇转速底层控制工具
//
//  用法:
//    CleanMateSMCHelper auto           -> 恢复系统自动温控 (F%dMd=0, Ftst=0)
//    CleanMateSMCHelper cool           -> 降温模式 50% 转速 (Ftst=1, F%dMd=1, F%dTg=50%)
//    CleanMateSMCHelper max            -> 强冷模式 100% 转速 (Ftst=1, F%dMd=1, F%dTg=100%)
//    CleanMateSMCHelper percent <0-100> -> 指定百分比转速 (0 为自动)
// ============================================================

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SMC_BUFFER_SIZE 80
#define SMC_CMD_READ_BYTES 5
#define SMC_CMD_WRITE_BYTES 6
#define SMC_CMD_READ_KEYINFO 9

static uint32_t fourcc(const char *s) {
    uint32_t r = 0;
    for (int i = 0; i < 4 && s[i]; i++) {
        r = (r << 8) | (uint8_t)s[i];
    }
    return r;
}

static bool smc_get_key_info(io_connect_t conn, uint32_t key, uint32_t *out_size, uint32_t *out_type) {
    uint8_t in_buf[SMC_BUFFER_SIZE];
    uint8_t out_buf[SMC_BUFFER_SIZE];
    memset(in_buf, 0, sizeof(in_buf));
    memset(out_buf, 0, sizeof(out_buf));

    memcpy(in_buf + 0, &key, sizeof(uint32_t));
    in_buf[42] = SMC_CMD_READ_KEYINFO;

    size_t out_len = SMC_BUFFER_SIZE;
    kern_return_t kr = IOConnectCallStructMethod(conn, 2, in_buf, SMC_BUFFER_SIZE, out_buf, &out_len);
    if (kr != kIOReturnSuccess || out_buf[40] != 0) {
        return false;
    }

    uint32_t dsize = 0, dtype = 0;
    memcpy(&dsize, out_buf + 28, sizeof(uint32_t));
    memcpy(&dtype, out_buf + 32, sizeof(uint32_t));
    if (dsize == 0 || dsize > 32) {
        return false;
    }
    if (out_size) *out_size = dsize;
    if (out_type) *out_type = dtype;
    return true;
}

static bool smc_read_double(io_connect_t conn, const char *key_str, double *out_val) {
    uint32_t key = fourcc(key_str);
    uint32_t dsize = 0, dtype = 0;
    if (!smc_get_key_info(conn, key, &dsize, &dtype)) {
        return false;
    }

    uint8_t in_buf[SMC_BUFFER_SIZE];
    uint8_t out_buf[SMC_BUFFER_SIZE];
    memset(in_buf, 0, sizeof(in_buf));
    memset(out_buf, 0, sizeof(out_buf));

    memcpy(in_buf + 0, &key, sizeof(uint32_t));
    memcpy(in_buf + 28, &dsize, sizeof(uint32_t));
    in_buf[42] = SMC_CMD_READ_BYTES;

    size_t out_len = SMC_BUFFER_SIZE;
    kern_return_t kr = IOConnectCallStructMethod(conn, 2, in_buf, SMC_BUFFER_SIZE, out_buf, &out_len);
    if (kr != kIOReturnSuccess || out_buf[40] != 0) {
        return false;
    }

    const uint8_t *b = out_buf + 48;
    if (dtype == fourcc("flt ") && dsize >= 4) {
        float f = 0;
        memcpy(&f, b, sizeof(float));
        if (isfinite(f)) {
            *out_val = (double)f;
            return true;
        }
    } else if (dtype == fourcc("fpe2") && dsize >= 2) {
        uint16_t raw = ((uint16_t)b[0] << 8) | (uint16_t)b[1];
        *out_val = (double)raw / 4.0;
        return true;
    } else if (dtype == fourcc("ui8 ") && dsize >= 1) {
        *out_val = (double)b[0];
        return true;
    } else if (dtype == fourcc("ui16") && dsize >= 2) {
        uint16_t raw = ((uint16_t)b[0] << 8) | (uint16_t)b[1];
        *out_val = (double)raw;
        return true;
    }
    return false;
}

static bool smc_write_bytes(io_connect_t conn, const char *key_str, const uint8_t *data, uint32_t data_len) {
    uint32_t key = fourcc(key_str);
    uint32_t dsize = 0, dtype = 0;
    if (!smc_get_key_info(conn, key, &dsize, &dtype)) {
        return false;
    }
    if (dsize != data_len || dsize > 32) {
        return false;
    }

    uint8_t in_buf[SMC_BUFFER_SIZE];
    uint8_t out_buf[SMC_BUFFER_SIZE];
    memset(in_buf, 0, sizeof(in_buf));
    memset(out_buf, 0, sizeof(out_buf));

    memcpy(in_buf + 0, &key, sizeof(uint32_t));
    memcpy(in_buf + 28, &dsize, sizeof(uint32_t));
    in_buf[42] = SMC_CMD_WRITE_BYTES;
    memcpy(in_buf + 48, data, dsize);

    size_t out_len = SMC_BUFFER_SIZE;
    kern_return_t kr = IOConnectCallStructMethod(conn, 2, in_buf, SMC_BUFFER_SIZE, out_buf, &out_len);
    return (kr == kIOReturnSuccess && out_buf[40] == 0);
}

static bool smc_write_uint8(io_connect_t conn, const char *key_str, uint8_t val) {
    return smc_write_bytes(conn, key_str, &val, 1);
}

static bool smc_write_rpm(io_connect_t conn, const char *key_str, double rpm) {
    uint32_t key = fourcc(key_str);
    uint32_t dsize = 0, dtype = 0;
    if (!smc_get_key_info(conn, key, &dsize, &dtype)) {
        return false;
    }
    if (dtype == fourcc("flt ") && dsize == 4) {
        float f = (float)rpm;
        uint8_t bytes[4];
        memcpy(bytes, &f, 4);
        return smc_write_bytes(conn, key_str, bytes, 4);
    } else if (dtype == fourcc("fpe2") && dsize == 2) {
        int clamped = (int)llround(rpm);
        if (clamped < 0) clamped = 0;
        if (clamped > 0x3fff) clamped = 0x3fff;
        uint16_t raw = (uint16_t)(clamped << 2);
        uint8_t bytes[2] = { (uint8_t)((raw >> 8) & 0xff), (uint8_t)(raw & 0xff) };
        return smc_write_bytes(conn, key_str, bytes, 2);
    }
    return false;
}

static bool resolve_fan_mode_key(io_connect_t conn, int idx, char out_key[5]) {
    char k1[8], k2[8];
    snprintf(k1, sizeof(k1), "F%dMd", idx);
    snprintf(k2, sizeof(k2), "F%dmd", idx);
    uint32_t sz = 0, tp = 0;
    if (smc_get_key_info(conn, fourcc(k1), &sz, &tp)) {
        memcpy(out_key, k1, 5);
        return true;
    }
    if (smc_get_key_info(conn, fourcc(k2), &sz, &tp)) {
        memcpy(out_key, k2, 5);
        return true;
    }
    return false;
}

static bool resolve_fan_target_key(io_connect_t conn, int idx, char out_key[5]) {
    char k1[8], k2[8];
    snprintf(k1, sizeof(k1), "F%dTg", idx);
    snprintf(k2, sizeof(k2), "F%dtg", idx);
    uint32_t sz = 0, tp = 0;
    if (smc_get_key_info(conn, fourcc(k1), &sz, &tp)) {
        memcpy(out_key, k1, 5);
        return true;
    }
    if (smc_get_key_info(conn, fourcc(k2), &sz, &tp)) {
        memcpy(out_key, k2, 5);
        return true;
    }
    return false;
}

static bool apply_auto_mode(io_connect_t conn, int fan_count) {
    bool ok = true;
    for (int i = 0; i < fan_count; i++) {
        char md_key[5];
        if (resolve_fan_mode_key(conn, i, md_key)) {
            if (!smc_write_uint8(conn, md_key, 0)) {
                ok = false;
            }
        }
    }
    uint32_t sz = 0, tp = 0;
    if (smc_get_key_info(conn, fourcc("FS! "), &sz, &tp) && sz == 2) {
        uint8_t zero2[2] = {0, 0};
        if (!smc_write_bytes(conn, "FS! ", zero2, 2)) ok = false;
    }
    if (smc_get_key_info(conn, fourcc("Ftst"), &sz, &tp)) {
        bool reset_ok = false;
        for (int attempt = 0; attempt < 20; attempt++) {
            if (smc_write_uint8(conn, "Ftst", 0)) {
                reset_ok = true;
                break;
            }
            usleep(100000);
        }
        ok = ok && reset_ok;
        usleep(150000);
        for (int i = 0; i < fan_count; i++) {
            char md_key[5];
            if (resolve_fan_mode_key(conn, i, md_key)) {
                if (!smc_write_uint8(conn, md_key, 0)) ok = false;
            }
        }
    }
    return ok;
}

static bool try_apply_manual_fans(io_connect_t conn, int fan_count, const double *targets, int max_Wait_ms) {
    for (int i = 0; i < fan_count; i++) {
        char md_key[5], tg_key[5];
        if (!resolve_fan_mode_key(conn, i, md_key) || !resolve_fan_target_key(conn, i, tg_key)) {
            return false;
        }
        bool md_ok = false;
        int waited = 0;
        while (waited <= max_Wait_ms) {
            if (smc_write_uint8(conn, md_key, 1)) {
                md_ok = true;
                break;
            }
            if (max_Wait_ms <= 0) break;
            usleep(100000);
            waited += 100;
        }
        if (!md_ok) return false;

        bool tg_ok = false;
        waited = 0;
        while (waited <= max_Wait_ms) {
            if (smc_write_rpm(conn, tg_key, targets[i])) {
                tg_ok = true;
                break;
            }
            if (max_Wait_ms <= 0) break;
            usleep(100000);
            waited += 100;
        }
        if (!tg_ok) return false;
    }
    return true;
}

static bool apply_manual_percent(io_connect_t conn, int fan_count, int percent) {
    double targets[8] = {0};
    for (int i = 0; i < fan_count; i++) {
        char mn_key[8], mx_key[8];
        snprintf(mn_key, sizeof(mn_key), "F%dMn", i);
        snprintf(mx_key, sizeof(mx_key), "F%dMx", i);
        double mn = 1200.0, mx = 6000.0;
        smc_read_double(conn, mn_key, &mn);
        smc_read_double(conn, mx_key, &mx);
        if (mx <= mn) mx = mn + 1000.0;

        double target = mn + (mx - mn) * ((double)percent / 100.0);
        if (percent >= 100) target = mx;
        if (target < mn) target = mn;
        if (target > mx) target = mx;
        targets[i] = round(target);
    }

    // 1. 尝试直接写入 F%dMd=1 与 F%dTg
    if (try_apply_manual_fans(conn, fan_count, targets, 0)) {
        return true;
    }

    // 2. Apple Silicon (M1/M2/M3/M4): 写入 Ftst=1 解锁 thermalmonitord，然后轮询写入 F%dMd=1 与 F%dTg
    uint32_t sz = 0, tp = 0;
    if (smc_get_key_info(conn, fourcc("Ftst"), &sz, &tp)) {
        if (!smc_write_uint8(conn, "Ftst", 1)) {
            return false;
        }
        usleep(500000); // 等待 0.5s 让 thermalmonitord 释放风扇控制锁
        if (try_apply_manual_fans(conn, fan_count, targets, 8000)) {
            return true;
        }
        // 若失败则回滚 Ftst=0
        smc_write_uint8(conn, "Ftst", 0);
    }
    return false;
}

int main(int argc, const char *argv[]) {
    if (geteuid() != 0) return 1;

    if (argc < 2) {
        fprintf(stderr, "Usage: CleanMateSMCHelper <auto|cool|max|percent> [0-100]\n");
        return 1;
    }

    int target_percent = 0;
    const char *cmd = argv[1];
    if (strcmp(cmd, "auto") == 0 || strcmp(cmd, "0") == 0) {
        target_percent = 0;
    } else if (strcmp(cmd, "cool") == 0 || strcmp(cmd, "50") == 0) {
        target_percent = 50;
    } else if (strcmp(cmd, "max") == 0 || strcmp(cmd, "100") == 0) {
        target_percent = 100;
    } else if (strcmp(cmd, "percent") == 0 && argc >= 3) {
        target_percent = atoi(argv[2]);
    } else {
        target_percent = atoi(cmd);
    }

    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) {
        fprintf(stderr, "AppleSMC service not found\n");
        return 2;
    }
    io_connect_t conn = 0;
    kern_return_t kr = IOServiceOpen(service, mach_task_self_, 0, &conn);
    IOObjectRelease(service);
    if (kr != kIOReturnSuccess || !conn) {
        fprintf(stderr, "Failed to open AppleSMC: 0x%x\n", kr);
        return 3;
    }

    double fnum_val = 0;
    if (!smc_read_double(conn, "FNum", &fnum_val) || (int)fnum_val <= 0) {
        IOServiceClose(conn);
        fprintf(stderr, "No controllable fans\n");
        return 4;
    }
    int fan_count = (int)fnum_val;
    if (fan_count > 8) fan_count = 8;

    bool ok = false;
    if (target_percent <= 0) {
        ok = apply_auto_mode(conn, fan_count);
    } else {
        if (target_percent > 100) target_percent = 100;
        ok = apply_manual_percent(conn, fan_count, target_percent);
    }

    IOServiceClose(conn);
    return ok ? 0 : 5;
}
