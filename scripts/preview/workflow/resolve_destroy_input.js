module.exports = async function resolveDestroyInput({ core, context }) {
  const eventName = context.eventName;

  if (eventName === "workflow_dispatch") {
    const envName = context.payload.inputs?.["env-name"] || "";
    if (!envName) {
      core.setFailed("Missing required workflow_dispatch input: env-name");
      return;
    }

    core.setOutput("skip", "false");
    core.setOutput("raw_env_name", envName);
    return;
  }

  if (eventName !== "issue_comment") {
    core.setOutput("skip", "true");
    return;
  }

  const issue = context.payload.issue;
  if (!issue || issue.pull_request) {
    core.setOutput("skip", "true");
    return;
  }

  const comment = (context.payload.comment?.body || "").trim().toLowerCase();
  if (comment !== "destroy-env") {
    core.setOutput("skip", "true");
    return;
  }

  const issueBody = issue.body || "";
  const envFromBody =
    issueBody.match(/^\s*(?:[-*]\s*)?(?:\*\*)?Environment(?:\*\*)?\s*:\s*`?([a-z0-9-]+)`?/im)?.[1] ||
    issueBody.match(/`([a-z0-9-]+)`/)?.[1];
  const envFromTitle = issue.title?.match(/^Preview\s*\/\s*([a-z0-9-]+)\b/i)?.[1];
  const resolvedEnv = envFromBody || envFromTitle;

  if (!resolvedEnv) {
    core.setFailed("Could not find environment name in issue body or title.");
    return;
  }

  core.setOutput("skip", "false");
  core.setOutput("raw_env_name", resolvedEnv);
};

