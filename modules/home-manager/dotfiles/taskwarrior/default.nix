{ config, pkgs, ... }:

{
  home.packages = [ pkgs.unstable.taskwarrior-tui ];

  programs.taskwarrior = {
    enable = true;
    package = pkgs.unstable.taskwarrior3;
    dataLocation = "${config.home.homeDirectory}/.task";
    colorTheme = "dark-16";
    config = {
      weekstart = "Monday";
      "print.empty.columns" = "no";
      "search.case.sensitive" = "no";
      regex = "on";
      "json.array" = "on";

      # Dynamic Matugen Theming (Inherits from kitty/alacritty 16-color palette)
      # color4 = primary, color1 = red/error, color3 = yellow/warning, color2 = green
      "color.alternate" = "on color8";
      "color.header" = "bold color4";
      "color.active" = "color15 on color4";
      "color.due" = "color3";
      "color.due.today" = "color1";
      "color.overdue" = "color15 on color1";
      "color.project" = "color2";
      "color.tag.next" = "bold color4";
      "color.tagged" = "color6";
      "color.urgency" = "bold color1";

      # UI Settings
      "verbose" = "blank,header,footnote,label,new-id,new-uuid,affected,edit,project,sync,unparsed";
      "bulk" = "0";
      "confirmation" = "yes";
      "news.version" = "3.0.0";

      # Date formatting
      "dateformat" = "Y-M-D";
      "dateformat.info" = "Y-M-D H:N";
      "dateformat.report" = "Y-M-D";
      "dateformat.holiday" = "Y-M-D";
      "dateformat.annotation" = "Y-M-D H:N";
      
      # Urgency Coefficients
      "urgency.user.tag.next.coefficient" = "15.0";
      "urgency.user.tag.today.coefficient" = "12.0";
      "urgency.due.coefficient" = "12.0";
      "urgency.active.coefficient" = "4.0";
      "urgency.scheduled.coefficient" = "5.0";
      "urgency.project.coefficient" = "0.0"; # Keep projects from inflating urgency too much
      "urgency.tags.coefficient" = "1.0";
      "urgency.waiting.coefficient" = "-3.0";

      # UDAs
      "uda.estimate.type" = "duration";
      "uda.estimate.label" = "Est";
      "uda.reviewed.type" = "date";
      "uda.reviewed.label" = "Reviewed";

      # Custom Reports
      "report.inbox.description" = "Inbox - Uncategorized tasks";
      "report.inbox.columns" = "id,entry.age,description,urgency";
      "report.inbox.labels" = "ID,Age,Description,Urg";
      "report.inbox.sort" = "urgency-";
      "report.inbox.filter" = "status:pending limit:page project: tags.none: ";

      "report.today.description" = "Tasks to do today";
      "report.today.columns" = "id,start.age,entry.age,depends,priority,project,tags,recur,scheduled.countdown,due.relative,until.remaining,description,urgency";
      "report.today.labels" = "ID,Active,Age,Deps,P,Project,Tags,Recur,S,Due,Until,Description,Urg";
      "report.today.sort" = "urgency-";
      "report.today.filter" = "status:pending and ( +today or due.before:eod )";

      "report.focus.description" = "High urgency active tasks";
      "report.focus.columns" = "id,priority,project,tags,due.relative,description,urgency";
      "report.focus.labels" = "ID,P,Project,Tags,Due,Description,Urg";
      "report.focus.sort" = "urgency-";
      "report.focus.filter" = "status:pending limit:10 urgency.over:10";

      # Contexts
      "context.work" = "project:Work";
      "context.home" = "project:Personal or project:Home";
      "context.none" = "";
    };
  };
}
