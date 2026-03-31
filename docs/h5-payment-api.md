# H5 Payment API Notes

## Overview

This document consolidates the reference materials that were previously stored in the temporary `h5文档和代码` folder.

The app currently uses three H5-related endpoints:

- `POST /H5Api/authH5`
- `POST /H5Api/authH5Test`
- `POST /H5Api/submitSuccessOrder`

## Base URL

- Example base URL: `https://app.vidoogo.com/api/`
- Production uses HTTPS

## Common Response Shape

```json
{
  "data": {},
  "message": "Success",
  "code": 200
}
```

## Auth Request

`authH5` and `authH5Test` share the same payload shape.

### Main fields

- `bundleId`
- `deviceNo`
- `requestIp`
- `card`
- `cnInput`
- `cnLanguage`
- `userAgent`
- `timezone`
- `appVersion`
- `callPay`
- `autozone`
- `lg`
- `lgs`
- `wifi`
- `charge`
- `powerLevel`

### Successful result

- Returns an H5 top-up entry URL in `data`

## Successful Order Verification

`submitSuccessOrder` is called after payment succeeds.

### Main fields

- `deviceNo`
- `appVersion`
- `requestIp`
- `bundleId`
- `transactionId`
- `receiptData`
- `version`

### Version behavior

- `v2` uses `transactionId`
- `v1` uses `receiptData`

## Runtime Integration

The active implementation now lives in:

- [H5PaymentService.swift](file:///Users/zhansi/Desktop/vibecoding/Eula/Eula/App/Services/H5PaymentService.swift)
- [WalletIAPService.swift](file:///Users/zhansi/Desktop/vibecoding/Eula/Eula/App/Services/WalletIAPService.swift)
- [WalletRechargeView.swift](file:///Users/zhansi/Desktop/vibecoding/Eula/Eula/UI/Wallet/WalletRechargeView.swift)

## Build Configuration

H5 behavior is controlled through build settings and Info.plist substitution:

- Debug: test H5 enabled
- Release: H5 disabled by default
