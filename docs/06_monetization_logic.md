# 6. Monetization Logic

## Pricing Model

| Tier | Price | Duration |
|------|-------|----------|
| Free | $0 | Forever |
| Premium | $4.99 | Lifetime (one-time) |

---

## Feature Gating Matrix

| Feature | Free | Premium |
|---------|------|---------|
| Create/Join lobbies | ✅ | ✅ |
| Standard question pool | ✅ | ✅ |
| AI-selected questions | 10/day | ✅ Unlimited |
| AI-generated questions | ❌ | ✅ |
| NSFW mode | ❌ | ✅ |
| Max rounds per game | 50 | 100 |
| Custom round count | 10, 20, 30, 50 | 10–100 (slider) |
| Custom question packs | ❌ | ✅ (future) |
| Custom categories | ❌ | ✅ (future) |
| Tone escalation | Full | Full |
| Multiplayer | ✅ | ✅ |
| Ads | None | None |

---

## Gating Implementation

### Client-Side Gate (Flutter)

```dart
class PremiumGate {
    final IPremiumRepository _premiumRepo;

    Future<bool> canUseNsfw() async {
        return await _premiumRepo.isPremium();
    }

    Future<bool> canUseAiGeneration() async {
        return await _premiumRepo.isPremium();
    }

    Future<int> getMaxRounds() async {
        final isPremium = await _premiumRepo.isPremium();
        return isPremium ? 100 : 50;
    }

    Future<List<int>> getAllowedRoundOptions() async {
        final isPremium = await _premiumRepo.isPremium();
        if (isPremium) {
            return List.generate(19, (i) => (i + 2) * 5); // 10, 15, 20, ..., 100
        }
        return [10, 20, 30, 50];
    }

    Future<bool> canMakeAiCall() async {
        final isPremium = await _premiumRepo.isPremium();
        if (isPremium) return true;
        
        final dailyCount = await _premiumRepo.getDailyAiCallCount();
        return dailyCount < 10;
    }
}
```

### Server-Side Gate (Fastify API)

```typescript
async function checkAiRateLimit(userId: string, pool: Pool): Promise<boolean> {
    const { rows: [premium] } = await pool.query(
        'SELECT is_premium FROM premium_status WHERE user_id = $1',
        [userId]
    );
    if (premium?.is_premium) return true;

    const { rows: [limits] } = await pool.query(
        'SELECT daily_ai_calls, last_reset_date FROM ai_rate_limits WHERE user_id = $1',
        [userId]
    );

    // Reset if new day
    if (limits?.last_reset_date !== today()) {
        await pool.query(
            'UPDATE ai_rate_limits SET daily_ai_calls = 0, last_reset_date = $1 WHERE user_id = $2',
            [today(), userId]
        );
        return true;
    }

    return (limits?.daily_ai_calls ?? 0) < 10;
}
```

---

## In-App Purchase Integration

### Provider: Custom (StoreKit 2 + Local Verification)

**Why custom instead of RevenueCat:**
- No third-party dependency or SDK
- Full control over receipt validation
- No revenue sharing with middleware
- Apple's `in_app_purchase` Flutter plugin is production-ready
- Local-only premium: device marked premium after StoreKit confirms purchase

### Architecture

```
┌─────────────┐    ┌──────────────┐    ┌───────────────────┐
│  Flutter App │──▶│  App Store   │──▶│  Purchase Sheet   │
│  StoreKit    │   │  (StoreKit2) │   │  (Native iOS)     │
│  Service     │◀──│              │◀──│                   │
└──────┬───────┘    └──────────────┘    └───────────────────┘
       │ confirmed
       ▼
┌──────────────┐
│  Local       │
│  SharedPrefs │
│  premium=true│
└──────────────┘
```

### Client-Side Flow

```dart
class StoreKitService {
  final InAppPurchase _iap = InAppPurchase.instance;

  Future<bool> purchasePremium() async {
    final product = await _loadProduct('nhie_premium_lifetime');
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  // Purchase stream handler marks device as premium locally
  // via SharedPreferences after StoreKit confirms
}
```

### Premium Status

Premium status is stored **locally on device** via `SharedPreferences`.
StoreKit 2 handles receipt validation natively — no server-side verification needed.

```dart
Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
}
```

---

## Premium Screen UX

```
┌──────────────────────────────────────────┐
│                                          │
│         ⭐ Go Premium ⭐                │
│                                          │
│  ┌────────────────┬───────────────────┐  │
│  │     FREE       │    PREMIUM        │  │
│  ├────────────────┼───────────────────┤  │
│  │ 10 AI Q/day    │ Unlimited AI      │  │
│  │ No NSFW        │ 🌶️ NSFW Mode     │  │
│  │ Max 50 rounds  │ Up to 100 rounds  │  │
│  │ Basic pool     │ Full pool         │  │
│  └────────────────┴───────────────────┘  │
│                                          │
│       ┌─────────────────────┐            │
│       │  Unlock for $4.99   │            │
│       │    One-time only    │            │
│       └─────────────────────┘            │
│                                          │
│       Restore Purchases                  │
│                                          │
└──────────────────────────────────────────┘
```

---

## Revenue Projections (Conservative)

| Metric | Estimate |
|--------|----------|
| Monthly installs | 5,000 |
| Free → Premium conversion | 5% |
| Premium purchases/month | 250 |
| Revenue/month | $1,245 (after Apple 30%) |
| Annual revenue | ~$15,000 |

Costs:
- Self-hosted backend (Raspberry Pi): $0
- Groq API Free Tier: $0 (up to 14,400 requests/day)
- Apple Developer: $99/year

**Net margin: ~97% until scale thresholds**
