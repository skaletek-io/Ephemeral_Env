module.exports = async function upsertPreviewIssue({
  github,
  context,
  envName,
  frontendUrl,
  backendUrl,
  dbPort,
  vpsHost,
  actor,
  runUrl,
  backRef,
  frontRef,
}) {
  const title = `Preview / ${envName}`;
  const sha = context.sha.slice(0, 7);

  const existing = await github.rest.issues.listForRepo({
    owner: context.repo.owner,
    repo: context.repo.repo,
    labels: "preview",
    state: "open",
  });

  const existingIssue = existing.data.find((i) => i.title === title);

  // If issue exists, preserve original branch lines from its body.
  let backendBranch = `\`${backRef}\``;
  let frontendBranch = `\`${frontRef}\``;

  if (existingIssue) {
    const bodyLines = (existingIssue.body || "").split("\n");
    const backLine = bodyLines.find((l) => l.startsWith("**Backend Branch:**"));
    const frontLine = bodyLines.find((l) => l.startsWith("**Frontend Branch:**"));
    if (backLine) backendBranch = backLine.replace("**Backend Branch:**", "").trim();
    if (frontLine) frontendBranch = frontLine.replace("**Frontend Branch:**", "").trim();
  }

  const body = `## Preview Environment

**Environment:** \`${envName}\`
**Backend Branch:** ${backendBranch}
**Frontend Branch:** ${frontendBranch}
**Last Commit:** \`${sha}\`
**Last Deployed by:** @${actor}

---

## Services

| Service    | Address                        |
|------------|--------------------------------|
| Frontend   | ${frontendUrl}                 |
| Backend    | ${backendUrl}                  |
| Postgres   | \`${vpsHost}:${dbPort}\`       |

---

## Details

[View workflow run](${runUrl})

> This issue was created automatically on deployment. Close it when the preview environment is torn down.
`;

  if (existingIssue) {
    await github.rest.issues.update({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: existingIssue.number,
      body,
    });
    console.log(`Updated issue #${existingIssue.number} for ${envName}`);
  } else {
    await github.rest.issues.create({
      owner: context.repo.owner,
      repo: context.repo.repo,
      title,
      labels: ["preview"],
      body,
    });
    console.log(`Created new issue for ${envName}`);
  }
};
