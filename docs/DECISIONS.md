# Product Decisions

| Decision | Why it matters | Status |
| --- | --- | --- |
| The product is named Geoffrey | It is personal and consistent across the app, installer, and docs. | Decided |
| Mac first | The initial experience focuses on one platform and can be polished there. | Decided |
| Geoffrey gets its own app window | Daily work should not require living in Terminal. | Decided |
| GitHub memory is part of onboarding | A private, portable memory gives Geoffrey continuity and user ownership. | Decided |
| Ask whether a person has GitHub; help create it if not | GitHub is required for memory, but should not block downloading Geoffrey. | Decided |
| Multiple email accounts are essential | Geoffrey exists partly to cover the limitation of a single email connection. | Decided |
| Gmail and Microsoft/Outlook are supported | Friends use both systems. | In progress |
| Account management belongs in the app menu | It stays available without crowding the daily interface. | Decided |
| Geoffrey learns from briefing feedback | The morning briefing must get more useful, not repeat generic output. | Decided |
| Updates run quietly and ask only when one exists | No recurring nuisance prompt. | Decided |
| Skills require owner approval before they are added | Geoffrey can grow without making silent changes. | Decided |
| The desktop app replaces the terminal interface | Dustin's existing terminal-created state is preserved, but normal use moves entirely into Geoffrey. | Decided |
| Claude Code remains the intelligence and tool runtime | Geoffrey makes Claude's skills, MCPs, connectors, and builders understandable instead of building a weaker parallel system. | Decided |
| The app installs a self-contained versioned engine | Replacing the app can update product code without overwriting private user state. | Implemented |
| Existing state is migrated non-destructively | Geoffrey backs up and inventories the old setup before using it in place. | Implemented |
| Cloud-first automation with a local queue | Cloud-capable workflows should run while the Mac is off; local-only dependencies wait and catch up visibly. | Decided; implementation pending |
| GitHub holds portable, non-secret owner state | Memory, approved skills, workflow definitions, and results remain owned and transferable; credentials never belong in GitHub. | Partially implemented |
| macOS Keychain will hold credentials | The current preserved account registry is a migration source, not the final security design. | Decided; implementation pending |
| The current Google OAuth flow is acceptable for the pilot | Commercial Gmail scope verification is deferred until Geoffrey is being prepared for market. | Pilot decision |
| Real user screenshots are not release artifacts | Fixtures and synthetic data provide evidence without exposing recipient information. | Decided and enforced |
| Dustin is involved only after the release gate passes | His machine is the acceptance environment, not the development environment. | Decided |
| Every release claim requires evidence | Automated checks, artifact inspection, or recorded human acceptance must prove the behavior. | Decided and enforced |
