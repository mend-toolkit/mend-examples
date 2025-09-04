// Make SBT use Ivy (so it honors ~/.sbt/repositories) — optional if you’ve wired Coursier separately
ThisBuild / useCoursier := false

// Ensure dependency resolution happens before compile (UA already runs 'compile')
ThisBuild / update / aggregate := true
Compile / compile := (Compile / compile).dependsOn(Compile / update).value
Test    / compile := (Test    / compile).dependsOn(Test    / update).value

// Be lenient on evictions to avoid failing builds just for version conflicts during scanning
ThisBuild / evictionErrorLevel := Level.Info
