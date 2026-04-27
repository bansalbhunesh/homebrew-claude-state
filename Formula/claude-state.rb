class ClaudeState < Formula
  desc "Session state, handoff, and resume tooling for Claude Code"
  homepage "https://github.com/bansalbhunesh/claude-code-handoff"
  url "https://github.com/bansalbhunesh/claude-code-handoff/archive/refs/tags/v0.6.1.tar.gz"
  sha256 "61e53a7385437adbd61467b95342ce3057da8756ae38fed6ee65de450a339bbb"
  license "MIT"

  depends_on "jq"

  def install
    # Install everything under libexec so bin/claude-state's upward walk
    # for lib/common.sh resolves to libexec/lib/common.sh as a
    # sibling-of-parent. No source patching required.
    libexec.install "bin", "lib", "modules", "commands"
    libexec.install "install.sh", "uninstall.sh"

    # Expose CLIs on PATH via symlinks into the Cellar's bin/.
    bin.install_symlink libexec/"bin/claude-state"
    bin.install_symlink libexec/"bin/claude-handoff"

    # Stage the install/uninstall scripts plus the slash command source
    # under pkgshare/ so caveats can point users at a stable path.
    pkgshare.install_symlink libexec/"install.sh"
    pkgshare.install_symlink libexec/"uninstall.sh"
    pkgshare.install_symlink libexec/"commands"
  end

  def caveats
    <<~EOS
      claude-state was installed, but the Claude Code hooks in
      ~/.claude/settings.json have NOT been wired up yet. To finish setup:

        bash #{opt_pkgshare}/install.sh           # core hooks
        bash #{opt_pkgshare}/install.sh --auto    # + auto-resume

      To install the /resume slash command into your Claude Code config:

        mkdir -p ~/.claude/commands
        cp #{opt_pkgshare}/commands/resume.md ~/.claude/commands/

      To uninstall the hooks (the formula files stay until `brew uninstall`):

        bash #{opt_pkgshare}/uninstall.sh
    EOS
  end

  test do
    # Smoke test: `help` exits 0 and produces output. This exercises the
    # libexec lib lookup (common.sh / workspace.sh sourcing) without
    # touching the user's real ~/.claude/.
    ENV["CLAUDE_HOME"] = testpath/".claude"
    (testpath/".claude").mkpath

    help_output = shell_output("#{bin}/claude-state help")
    assert_match "claude-state", help_output
    assert_match "resume", help_output

    # The deprecation shim should forward to claude-state and print its
    # deprecation notice on stderr.
    shim_output = shell_output("#{bin}/claude-handoff help 2>&1")
    assert_match "deprecated", shim_output
    assert_match "claude-state", shim_output
  end
end
