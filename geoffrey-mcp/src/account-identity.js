// Resolve desktop account names only after the provider verifies the mailbox.
// Keep existing aliases stable: skills and workflows may refer to those ids.
export function resolveAccountIdentity({ provider, email, accounts, id, purpose, expectedEmail }) {
  const normalized = (value) => typeof value === "string" ? value.trim().toLowerCase() : "";
  const verifiedEmail = normalized(email);
  if (!verifiedEmail || !verifiedEmail.includes("@")) {
    throw new Error("The provider did not identify an email address. No account was changed.");
  }
  if (expectedEmail && normalized(expectedEmail) !== verifiedEmail) {
    throw new Error("You signed in to a different email address. No account was changed. Try again and choose the original account.");
  }
  if (id) {
    const previous = accounts.find((account) => account.id === id);
    if (previous && (previous.provider !== provider || normalized(previous.email) !== verifiedEmail)) {
      throw new Error("This account name belongs to a different mailbox. No account was changed.");
    }
    return { id, purpose: purpose ?? previous?.purpose ?? "" };
  }
  const previous = accounts.find((account) => account.provider === provider && normalized(account.email) === verifiedEmail);
  if (previous) return { id: previous.id, purpose: previous.purpose ?? "" };
  // Account ids are global across providers. Never overwrite an unrelated one.
  const base = verifiedEmail;
  let candidate = base;
  for (let suffix = 2; accounts.some((account) => account.id === candidate); suffix++) {
    candidate = `${base} (${provider} ${suffix})`;
  }
  return { id: candidate, purpose: purpose ?? "" };
}
