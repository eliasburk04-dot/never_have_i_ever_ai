# 10. Future Expansion Possibilities

## Phase 2 Features (v1.1 — Month 2–3)

### Custom Question Packs (Premium)
- Users create personal question packs
- New table: `custom_question_packs` + `custom_questions`
- Host selects pack when creating lobby
- AI can mix custom + standard pool questions
- Share packs via link (future social feature)

### Friend System
- Upgrade from anonymous to linked accounts (Apple Sign-In)
- Friend list stored in Postgres
- Quick invite via push notification
- Persistent display names across sessions

### Game History
- Optional: save game summaries for authenticated users
- View past group profiles
- "Play again with same group" shortcut

---

## Phase 3 Features (v1.2 — Month 4–6)

### Android Release
- Flutter already cross-platform
- Add Google Play billing (in_app_purchase plugin supports both stores)
- Adjust safety filters for Google Play policies
- Test Realtime performance on Android

### Themed Game Modes
- **Couples Edition**: Relationship-focused questions (2 players)
- **Work Party**: Team-building safe questions (no NSFW)
- **College Night**: Party-friendly, higher baseline intensity
- Each mode = different starting parameters + filtered question pool

### Spectator Mode
- Non-playing viewers can watch rounds
- See question + group results
- No answer submission
- Useful for streams / watch parties

---

## Phase 4 Features (v2.0 — Month 6–12)

### AI Personality Narration
- AI generates witty commentary on group results
- "Wow, 5 out of 6 of you have stolen a fry from someone's plate. Relatable."
- Displayed between rounds
- Uses Groq text generation (separate prompt)

### Leaderboard / Achievements
- "Most Honest Player" badge
- "Group Explorer" — played with 50+ unique players
- "Night Owl" — played after midnight
- Weekly global stats (anonymized)

### Web Companion
- Flutter Web version for lobby management
- QR code for easy lobby join
- Web dashboard showing live game state

### Voice Mode (Experimental)
- Instead of reading questions, TTS reads them aloud
- Players answer on their own phone
- Party-friendly hands-free experience
- Use device TTS or Groq TTS API (when available)

---

## Phase 5 Features (v2.5+)

### AI Photo Challenges
- Between rounds, AI suggests a group photo challenge
- "Everyone who said 'I have' — make your guiltiest face"
- Photo stored temporarily (session only), shared in-lobby
- Privacy: auto-deleted after lobby ends

### Tournament Mode
- Multiple lobbies compete
- Lobby-vs-lobby scoring
- Group boldness compared across tables
- Great for events / parties

### API / SDK for Third-Party Integration
- Public API for creating custom "Never Have I Ever" experiences
- Embed in other apps / websites
- Partner with event companies

---

## Technical Debt to Address

| Item | Priority | When |
|------|----------|------|
| Add comprehensive unit tests for BLoCs | High | Before launch |
| Add integration tests for Edge Functions | High | Before launch |
| Implement proper analytics pipeline | Medium | v1.1 |
| Add A/B testing framework for question selection | Medium | v1.2 |
| Migrate to Riverpod if BLoC complexity grows | Low | v2.0 |
| Add offline question caching for lobby creation | Low | v1.2 |
| Implement question quality scoring feedback loop | Medium | v1.1 |

---

## Long-Term Vision

```
v1.0: Core game, AI escalation, 3 languages, premium
v1.1: Custom packs, friend system, game history
v1.2: Android, themed modes, spectator
v2.0: AI narration, achievements, web companion
v2.5: Photo challenges, tournaments
v3.0: SDK/API, platform expansion
```

**Goal**: Become the #1 "Never Have I Ever" party game globally, with the most intelligent adaptive question engine on the market.
