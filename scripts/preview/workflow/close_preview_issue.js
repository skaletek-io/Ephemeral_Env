module.exports = async function closePreviewIssue({ github, context, envName }) {
  const owner = context.repo.owner;
  const repo = context.repo.repo;
  let issue;

  if (context.eventName === "issue_comment") {
    issue = context.payload.issue;
  } else {
    const issues = await github.rest.issues.listForRepo({
      owner,
      repo,
      labels: "preview",
      state: "open",
    });
    issue = issues.data.find((i) => i.title === `Preview / ${envName}`);
  }

  if (!issue) {
    console.log(`No open preview issue found for ${envName}`);
    return;
  }

  if (issue.state === "closed") {
    console.log(`Issue #${issue.number} is already closed`);
    return;
  }

  await github.rest.issues.update({
    owner,
    repo,
    issue_number: issue.number,
    state: "closed",
  });

  console.log(`Closed issue #${issue.number} for ${envName}`);
};

