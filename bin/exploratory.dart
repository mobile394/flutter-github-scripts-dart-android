import 'package:flutter_github_scripts/github_datatypes.dart';
import 'package:flutter_github_scripts/github_queries.dart';
import 'package:args/args.dart';
import 'dart:io';



class Options  {
  final _parser = ArgParser(allowTrailingOptions: false);
  ArgResults _results;
  bool get showClosed => _results['closed'];
  DateTime get from => DateTime.parse(_results.rest[0]);
  DateTime get to => DateTime.parse(_results.rest[1]);
  int get exitCode => _results == null ? -1 : _results['help'] ? 0 : null;

  Options(List<String> args) {
    _parser
      ..addFlag('help', defaultsTo: false, abbr: 'h', negatable: false, help: 'get usage')
      ..addFlag('closed', defaultsTo: false, abbr: 'c', negatable: false, help: 'show punted issues in date range');
    try {
      _results = _parser.parse(args);
      if (_results['help'])  _printUsage();
      if (_results['closed'] && _results.rest.length != 2 ) throw('need start and end dates!');
    } on ArgParserException catch (e) {
      print(e.message);
      _printUsage();
    }
  }

  void _printUsage() {
    print('Usage: pub exploratory prs.dart [-closed fromDate toDate]');
    // TODO
    print('TODO');
    print('  Dates are in ISO 8601 format');
    print(_parser.usage);
  }
}

void main(List<String> args) async {
  final opts = Options(args);
  if (opts.exitCode != null) exit(opts.exitCode);

  var repos = ['flutter'];

  final token = Platform.environment['GITHUB_TOKEN'];
  final github = GitHub(token);

  var state = GitHubIssueState.open;
  DateRange when = null;
  var rangeType = GitHubDateQueryType.none;
  if (opts.showClosed) {
    state = GitHubIssueState.closed;
    when = DateRange(DateRangeType.range, start: opts.from, end: opts.to);
    rangeType = GitHubDateQueryType.closed;
  }

  var issues = List<dynamic>();
  for(var repo in repos) {
    issues.addAll(await github.fetch(owner: 'flutter', 
      name: repo, 
      type: GitHubIssueType.issue,
      state: state,
      dateQuery: rangeType,
      dateRange: when
    ));
  }

  print(opts.showClosed ? 
    "# Closed issues from " + opts.from.toIso8601String() + ' to ' + opts.to.toIso8601String() :
    "# Open issues" );

  if (false) {
    print('## All issues\n');
    for (var pr in issues) print(pr.summary(linebreakAfter: true));
    print('\n');
  }

  print("There were ${issues.length} issues.\n");

  var noMilestones = List<Issue>();
  var noAssigneesYetMilestoned = List<Issue>();
  int processed = 0;
  for(var item in issues) {
    var issue = item as Issue;
    processed++;
    if (issue.assignees != null && issue.assignees.length != 0 && issue.milestone == null ) {
      noMilestones.add(issue);
    }
    if (issue.milestone != null && (issue.assignees == null || issue.assignees.length == 0)) {
      if (issue.milestone.title == 'Goals' || 
         (issue.milestone.title == 'Stretch Goals') || 
         (issue.milestone.title == 'No milestone necessary') ||
         (issue.milestone.title == 'Near-term Goals')
         ) continue;
      noAssigneesYetMilestoned.add(issue);
    }
  }

  var clusters = Cluster.byAssignees(noMilestones);

  print('## Owned issues with no milestone by owner (${noMilestones.length})\n');
  print(clusters.toMarkdown(ClusterReportSort.byKey, true));

  print('## Issues with milestones and no owners (${noAssigneesYetMilestoned.length})');
  for(var issue in noAssigneesYetMilestoned) {
    print(issue.summary(linebreakAfter: true, boldInteresting: false));
  }



}