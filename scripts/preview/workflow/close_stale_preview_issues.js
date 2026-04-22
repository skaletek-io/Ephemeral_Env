module.exports = async function closeStalePreviewIssues({
  github,
  context,
  deletedEnvsRaw,
}) {
  const deletedEnvs = (deletedEnvsRaw || "")
    .split("\n")
    .map((v) => v.trim())
    .filter(Boolean);

  if (deletedEnvs.length === 0) {
    console.log("No deleted envs found; nothing to close.");
    return;
  }

  const owner = context.repo.owner;
  const repo = context.repo.repo;

  const issues = await github.rest.issues.listForRepo({
    owner,
    repo,
    labels: "preview",
    state: "open",
    per_page: 100,
  });

  const openByTitle = new Map(issues.data.map((issue) => [issue.title, issue]));

  for (const envName of deletedEnvs) {
    const title = `Preview / ${envName}`;
    const issue = openByTitle.get(title);

    if (!issue) {
      console.log(`No open preview issue found for ${envName}`);
      continue;
    }

    await github.rest.issues.update({
      owner,
      repo,
      issue_number: issue.number,
      state: "closed",
    });

    console.log(`Closed issue #${issue.number} for ${envName}`);
  }
};

