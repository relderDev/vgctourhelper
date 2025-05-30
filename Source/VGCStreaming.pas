unit VGCStreaming;

interface

uses
  SysUtils, Classes, Xml.XMLIntf,
  AK.Base, AK.RepositoryManagers,
  VGCTournament, VGCPlayer;

type
  /// <summary>
  ///  Encapsulates all the "printing" utility and adds it on a tournament. All
  ///  the HTML logic should be put in here.
  /// </summary>
  TVGCTourOutputHandler = class
  strict private
    FTournament: TVGCTournament;
    FTeamlistHtml: string;
    FPokemonHtml: string;
    FPairingsHtml: string;
    FStandingsHtml: string;
    FTournamentHtml: string;
    FOverlayHtml: string;
    FMatchesCSS: string;
    FPlayerCSS: string;
    FTemplatesLoaded: Boolean;
    procedure LoadTemplates;
    procedure Log(const AString: string; const AValues: array of const; const ALevel: Integer); overload;
    procedure Log(const AString: string; const ALevel: Integer); overload;
    procedure PrintPlayerTeamlist(const AOutputPath: string; const APlayer: TVGCPlayer; const AAfterPrint: TProc<string, string>);
    function ExpandPathMacros(const AString: string): string;
    function GetContextProp(const AName: string; const ADefault: string = ''): string;
    function GetDefaultIncludes(const AName: string): string;
    function GetPairings(const AFormat: string): string;
    function GetPlayerStandings(const APlayer: TVGCPlayer; const AIndex: Integer): string;
    function GetTeamlistHtml: string;
    function GetPokemonHtml: string;
    function GetPairingsHtml: string;
    function GetStandingsHtml: string;
    function GetTournamentHtml: string;
    function GetRoundsHeaderHtml: string;
    function GetTeamlistTemplate: string;
    function GetPokemonTemplate: string;
    function GetPairingsTemplate: string;
    function GetStandingsTemplate: string;
    function GetTournamentTemplate: string;
    function GetOverlayTemplate: string;
    function GetTeamlistOutputPath: string;
    function GetPairingsOutput: string;
    function GetStandingsOutput: string;
    function GetOverlayOutput: string;
    function GetP1Output: string;
    function GetP2Output: string;
    function GetTranslateTeamlist: Boolean;
  protected
    property TeamlistHtml: string read GetTeamlistHtml;
    property PokemonHtml: string read GetPokemonHtml;
    property PairingsHtml: string read GetPairingsHtml;
    property StandingsHtml: string read GetStandingsHtml;
    property TournamentHtml: string read GetTournamentHtml;
    property RoundsHeaderHtml: string read GetRoundsHeaderHtml;
    procedure PrintSingleTeamlist(const APlayerId: string; const AAfterPrint: TProc<string, string>);
    procedure PrintPlayerTeamlists(const AAfterPrint: TProc<string, string>);
    procedure PrintPairings(const AIncludePath: string = '');
    procedure PrintStandings(const AIncludePath: string = '');
    procedure PrintMatch(const AMatch: TVGCMatch);
    function GetIncludes(const AName: string): string;
    function InsertIncludes(const AHtml: string; const AIncludePath: string = ''): string;
    function MatchAsHtml(const ATableNumber: Integer; const AMatch: TVGCMatch; const AAnchorPath: string): string;
    function RoundAsHtml(const ARound: TVGCRound; const AAnchorPath: string): string; overload; virtual;
    function RoundAsHtml(const ARoundIndex: Integer; const AAnchorPath: string): string; overload;
    function GetPairingsHtmlContent(const AIncludePath: string): string; virtual;
    function GetStandingsHtmlContent(const AIncludePath: string): string; virtual;
  public
    property Tournament: TVGCTournament read FTournament;
    property TeamlistTemplate: string read GetTeamlistTemplate;
    property PokemonTemplate: string read GetPokemonTemplate;
    property PairingsTemplate: string read GetPairingsTemplate;
    property StandingsTemplate: string read GetStandingsTemplate;
    property TournamentTemplate: string read GetTournamentTemplate;
    property OverlayTemplate: string read GetOverlayTemplate;
    property TeamlistOutputPath: string read GetTeamlistOutputPath;
    property PairingsOutput: string read GetPairingsOutput;
    property StandingsOutput: string read GetStandingsOutput;
    property OverlayOutput: string read GetOverlayOutput;
    property P1Output: string read GetP1Output;
    property P2Output: string read GetP2Output;
    property TranslateTeamlist: Boolean read GetTranslateTeamlist;
    property MatchesCSS: string read FMatchesCSS write FMatchesCSS;
    property PlayerCSS: string read FPlayerCSS write FPlayerCSS;
    constructor Create(const ATournament: TVGCTournament);
  end;

  /// <summary>
  ///  Incorporates both the HTML outputs of TVGCTourOutputHandler class and the
  ///  integration with a Github repository. The Github repository is integrated
  ///  only when the "GithubRepoOwner" and "GithubRepoName" config properties
  ///  are defined on the PokemonContext.
  /// </summary>
  TVGCStreamingTournament = class(TVGCTournament)
  strict private
    FOutputHandler: TVGCTourOutputHandler;
    FTourHtml: string;
    FLastRoundHtml: string;
    FRepoBranch: string;
    FRepo: TAKRepoManager;
    const REPO_MESSAGE = 'Tour helper %s upload for tournament "%s".';
    procedure ExpandTournamentMacros(var AString: string);
    procedure PushTournament;
    procedure UpdateTournamentFile;
    function RepoMessage(const AUploadType: string): string;
    function GetTourFileName: string;
    function GetRoundsFileName: string;
    function GetTeamlistRepoPath: string;
    function GetOutputRepoPath: string;
    function GetResourcesRepoPath: string;
  strict protected
    property TourFileName: string read GetTourFileName;
    property RoundsFileName: string read GetRoundsFileName;
    procedure AfterInitialization; override;
    procedure AfterUpdate(const AUpdatedRounds: array of Integer; const ANewRoundStarted: Boolean); override;
  public
    property OutputHandler: TVGCTourOutputHandler read FOutputHandler;
    property Repository: TAKRepoManager read FRepo;
    property RepoBranch: string read FRepoBranch write FRepoBranch;
    property OutputRepoPath: string read GetOutputRepoPath;
    property TeamlistRepoPath: string read GetTeamlistRepoPath;
    property ResourcesRepoPath: string read GetResourcesRepoPath;
    procedure PrintPlayerTeamlists;
    procedure PrintSingleTeamlist(const APlayerId: string);
    procedure PrintMatch(const AMatch: TVGCMatch);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  StrUtils,
  AK.Constants, AK.Utils,
  Pokemon.Context;

{ TVGCTourOutputHandler }

constructor TVGCTourOutputHandler.Create(const ATournament: TVGCTournament);
begin
  Assert(Assigned(ATournament), 'A VGCStream object needs a valid VGCTournament.');

  inherited Create;
  FTournament := ATournament;
  FMatchesCSS := 'vgc-matches';
  FPlayerCSS := 'vgc-player';
  FTemplatesLoaded := False;
end;

function TVGCTourOutputHandler.ExpandPathMacros(const AString: string): string;
begin
  Result := ReplaceText(ReplaceText(AString, '{App}', AppPath),
    '{TournamentName}', Tournament.Name);
end;

{ NOT NEEDED ANYMORE: changed behaviour for tournament includes
function TVGCTourOutputHandler.GetAllIncludes: string;
const
  DEFAULT_NAMES: array[0..3] of string = ('Teamlist', 'Pairings', 'Standings');
var
  LName: string;
begin
  for LName in DEFAULT_NAMES do
    Result := Result + ' ' + GetIncludes(LName);

  LName := '';
  PokemonContext.Config.EnumFieldNames(
    procedure (const AFieldName: string)
    begin
      LName := LName + ' ' + GetContextProp(AFieldName);
    end,
    function (const AFieldName: string): Boolean
    begin
      Result := AFieldName.EndsWith('Includes', True);
      if Result then
        Result := not MatchText(AFieldName, DEFAULT_NAMES);
    end);

  Result := Result + LName;
  Delete(Result, Low(Result), 1);
end;
}

function TVGCTourOutputHandler.GetContextProp(const AName, ADefault: string): string;
begin
  Result := ExpandPathMacros(PokemonContext.Config.GetString(AName, ADefault))
end;

function TVGCTourOutputHandler.GetDefaultIncludes(const AName: string): string;
var
  LPath: string;
begin
  LPath := ConcatPath(['{App}', 'Resources']);
  if MatchText(AName, ['Teamlist', 'Pairings', 'Standings']) then
    Result := LPath + LowerCase(AName) + '.css';
  if SameText(AName, 'Teamlist') then
    Result := Result + ' ' + LPath + 'pokemon.css';
  if SameText(AName, 'Github') then
  begin
    LPath := ConcatPath([LPath, 'Repository']);
    Result := LPath + 'tournament.js ' + LPath + 'tournament.css ' +
      LPath + 'teamlist.css ' + LPath + 'pokemon.css ' + LPath + 'pairings.css ' +
      LPath + 'standings.css';
  end;
  Result := ExpandPathMacros(Result);
end;

function TVGCTourOutputHandler.GetIncludes(const AName: string): string;
begin
  Result := GetContextProp(AName + 'Includes');
  if Result = '' then
    Result := GetDefaultIncludes(AName);
end;

function TVGCTourOutputHandler.GetOverlayOutput: string;
begin
  Result := GetContextProp('OverlayOutput',
    ConcatPath(['{App}', 'Outputs', 'Stream']) + 'overlay.html');
end;

function TVGCTourOutputHandler.GetOverlayTemplate: string;
begin
  Result := GetContextProp('OverlayTemplate');
end;

function TVGCTourOutputHandler.GetP1Output: string;
begin
  Result := GetContextProp('Player1Output',
    ConcatPath(['{App}', 'Outputs', 'Stream']) + 'player1.html');
end;

function TVGCTourOutputHandler.GetP2Output: string;
begin
  Result := GetContextProp('Player2Output',
    ConcatPath(['{App}', 'Outputs', 'Stream']) + 'player2.html');
end;

function TVGCTourOutputHandler.GetPairings(const AFormat: string): string;
var
  LLastRound: TVGCRound;
  LFormat: Char;
begin
  LLastRound := Tournament.LastRound;
  Assert(Assigned(LLastRound), 'No round has started, call NextRound to start the first round.');

  if AFormat = '' then
    LFormat := 'H'
  else
    LFormat := UpCase(AFormat[Low(AFormat)]);
  case LFormat of
    'T': Result := LLastRound.AsString;
    'H': Result := RoundAsHtml(LLastRound, '');
    'J': Result := LLastRound.AsJSONString;
    else raise Exception.CreateFmt('Unsupported pairing format "%s".', [AFormat]);
  end;
end;

function TVGCTourOutputHandler.GetPairingsHtml: string;
begin
  if not FTemplatesLoaded then
    LoadTemplates;
  Result := FPairingsHtml;
end;

function TVGCTourOutputHandler.GetPairingsHtmlContent(const AIncludePath: string): string;
begin
  Result := InsertIncludes(PairingsHtml, AIncludePath);
  Result := ReplaceAndIndent(Result, '%Pairings%', GetPairings('H'));
end;

function TVGCTourOutputHandler.GetPairingsOutput: string;
begin
  Result := GetContextProp('PairingsOutput',
    ConcatPath(['{App}', 'Outputs', 'Stream']) + 'pairings.html');
end;

function TVGCTourOutputHandler.GetPairingsTemplate: string;
begin
  Result := GetContextProp('PairingsTemplate');
end;

function TVGCTourOutputHandler.GetPlayerStandings(const APlayer: TVGCPlayer;
  const AIndex: Integer): string;
const
  HTML = '<div class="player-standing%s">' +
    '<span class="%s">%s</span>' +
    '<span class="%1:s-score">%3:s</span>' +
    '<span class="%1:s-oppwr">%4:s%%</span>' +
    '<span class="%1:s-oppoppwr">%5:s%%</span></div>';
begin
  Result := Format(HTML, [IfThen(Tournament.IsCut(AIndex), ' topcut'),
    PlayerCSS, APlayer.AsString, APlayer.Score, APlayer.OppWinratePerc,
    APlayer.OppOppWinratePerc]);
end;

function TVGCTourOutputHandler.GetPokemonHtml: string;
begin
  if not FTemplatesLoaded then
    LoadTemplates;
  Result := FPokemonHtml;
end;

function TVGCTourOutputHandler.GetPokemonTemplate: string;
begin
  Result := GetContextProp('PokemonTemplate',
    ConcatPath(['{App}', 'Resources']) + 'pokemon.html');
end;

function TVGCTourOutputHandler.GetRoundsHeaderHtml: string;
const
  ROUND_TEMPLATE = '<div id="round-%d-header" index="%0:d" class="vgc-round-header%s">%s</div>';
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Tournament.RoundCount - 1 do
    if I = Tournament.RoundCount - 1 then
      Result := Result + Format(ROUND_TEMPLATE, [I, ' vgc-round-active', Tournament.Rounds[I].DisplayName])
    else
      Result := Result + Format(ROUND_TEMPLATE, [I, '', Tournament.Rounds[I].DisplayName]) + sLineBreak;
end;

function TVGCTourOutputHandler.GetStandingsHtml: string;
begin
  if not FTemplatesLoaded then
    LoadTemplates;
  Result := FStandingsHtml;
end;

function TVGCTourOutputHandler.GetStandingsHtmlContent(const AIncludePath: string): string;
var
  LIndex: Integer;
  LPlayers: string;
begin
  LIndex := 0;
  Result := InsertIncludes(StandingsHtml, AIncludePath);

  LPlayers := '<div id="standings" class="standings-container">';
  Tournament.Players.EnumPlayersSorted(procedure (const APlayer: TVGCPlayer)
    begin
      LPlayers := LPlayers + sLineBreak + '  ' + GetPlayerStandings(APlayer, LIndex);
      Inc(LIndex);
    end, Tournament.WinnerId);
  LPlayers := LPlayers + sLineBreak + '</div>' + sLineBreak;
  Result := ReplaceAndIndent(Result, '%Standings%', LPlayers);
end;

function TVGCTourOutputHandler.GetStandingsOutput: string;
begin
  Result := GetContextProp('StandingsOutput',
    ConcatPath(['{App}', 'Outputs', 'Stream']) + 'standings.html');
end;

function TVGCTourOutputHandler.GetStandingsTemplate: string;
begin
  Result := GetContextProp('StandingsTemplate');
end;

function TVGCTourOutputHandler.GetTeamlistHtml: string;
begin
  if not FTemplatesLoaded then
    LoadTemplates;
  Result := FTeamlistHtml;
end;

function TVGCTourOutputHandler.GetTeamlistOutputPath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetContextProp('TeamlistOutputPath',
    ConcatPath(['{App}', 'Outputs', '{TournamentName}', 'Teamlists'])));
end;

function TVGCTourOutputHandler.GetTeamlistTemplate: string;
begin
  Result := GetContextProp('TeamlistTemplate',
    ConcatPath(['{App}', 'Resources']) + 'teamlist.html');
end;

function TVGCTourOutputHandler.GetTournamentHtml: string;
begin
  if not FTemplatesLoaded then
    LoadTemplates;
  Result := FTournamentHtml;
end;

function TVGCTourOutputHandler.GetTournamentTemplate: string;
begin
  Result := GetContextProp('TournamentTemplate');
end;

function TVGCTourOutputHandler.GetTranslateTeamlist: Boolean;
begin
  Result := PokemonContext.Config.GetBoolean('TranslateTeamlist');
end;

function TVGCTourOutputHandler.InsertIncludes(const AHtml, AIncludePath: string): string;
var
  LReplacer: TAKMacroReplacer;
begin
  LReplacer := TAKMacroReplacer.Create('%INCLUDE:', '%',
    function (const AMatch, AInput: string; const AIndex: Integer): string
    begin
      Result := HTMLInclude(GetIncludes(AMatch).Split([' ']), AIncludePath);
      Result := ReplaceText(Result, '{App}', AppPath);
    end, True);
  Result := LReplacer.Replace(AHtml);
end;

procedure TVGCTourOutputHandler.LoadTemplates;
const
  PAIRINGS_TEMPLATE = '<!DOCTYPE html>' + sLineBreak + '<html>' + sLineBreak +
    '  <head>' + sLineBreak + '    %INCLUDE:Pairings%' + sLineBreak +
    '    <meta name="viewport" content="width=device-width, initial-scale=1">' + sLineBreak +
    '  </head>' + sLineBreak +
    '  <body>' + sLineBreak +
    '    <div class="vgc-pairings">' + sLineBreak +
    '      %Pairings%' + sLineBreak + '    </div>' + sLineBreak +
    '  </body>' + sLineBreak + '</html>';
  STANDINGS_TEMPLATE = '<!DOCTYPE html>' + sLineBreak + '<html>' + sLineBreak +
    '  <head>' + sLineBreak + '    %INCLUDE:Standings%' + sLineBreak +
    '    <meta name="viewport" content="width=device-width, initial-scale=1">' + sLineBreak +
    '  </head>' + sLineBreak +
    '  <body>' + sLineBreak + '    <div class="vgc-standings">' + sLineBreak +
    '      <div class="standings-header standings-container">' + sLineBreak +
    '        <div class="player-standing standing-header">' + sLineBreak +
    '          <span class="vgc-player">Player</span><span>Score</span><span>Op w/r</span><span>OpOp w/r</span>' + sLineBreak +
    '        </div>' + sLineBreak +
    '      </div>' + sLineBreak +
    '      %Standings%' + sLineBreak + '    </div>' + sLineBreak +
    '  </body>' + sLineBreak + '</html>';
  TOURNAMENT_TEMPLATE = '<!DOCTYPE html>' + sLineBreak + '<html>' + sLineBreak +
    '  <head>' + sLineBreak + '    %INCLUDE:Pairings%' + sLineBreak +
    '    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">' + sLineBreak +
    '    <meta http-equiv="Pragma" content="no-cache">' + sLineBreak +
    '    <meta http-equiv="Expires" content="0">' + sLineBreak +
    '    <meta name="viewport" content="width=device-width, initial-scale=1">' + sLineBreak +
    '    %INCLUDE:Tournament%' + sLineBreak + '  </head>' + sLineBreak +
    '  <body>' + sLineBreak +
    '    <div class="vgc-pairings">' + sLineBreak +
    '      <div class="vgc-pairings-header">' + sLineBreak +
    '        %RoundsHeader%' + sLineBreak + '      </div>' + sLineBreak +
    '      <div class="vgc-pairings-body">' + sLineBreak +
    '        %RoundsContent%' + sLineBreak + '      </div>' + sLineBreak +
    '    </div>' + sLineBreak +
    '  </body>' + sLineBreak + '</html>';
begin
  Assert(FileExists(TeamlistTemplate));
  Assert(FileExists(PokemonTemplate));

  FTeamlistHtml := LoadTextFromFile(TeamlistTemplate);
  FPokemonHtml := LoadTextFromFile(PokemonTemplate);
  if FileExists(PairingsTemplate) then
    FPairingsHtml := LoadTextFromFile(PairingsTemplate)
  else
    FPairingsHtml := PAIRINGS_TEMPLATE;
  if FileExists(StandingsTemplate) then
    FStandingsHtml := LoadTextFromFile(StandingsTemplate)
  else
    FStandingsHtml := STANDINGS_TEMPLATE;
  if FileExists(TournamentTemplate) then
    FTournamentHtml := LoadTextFromFile(TournamentTemplate)
  else
    FTournamentHtml := TOURNAMENT_TEMPLATE;
  if FileExists(OverlayTemplate) then
    FOverlayHtml := LoadTextFromFile(OverlayTemplate);
  FTemplatesLoaded := True;
end;

procedure TVGCTourOutputHandler.Log(const AString: string;
  const ALevel: Integer);
begin
  FTournament.Logger.Log(AString, ALevel);
end;

procedure TVGCTourOutputHandler.Log(const AString: string;
  const AValues: array of const; const ALevel: Integer);
begin
  FTournament.Logger.Log(AString, AValues, ALevel);
end;

function TVGCTourOutputHandler.MatchAsHtml(const ATableNumber: Integer;
  const AMatch: TVGCMatch; const AAnchorPath: string): string;
const
  ANCHOR_TEMPLATE = '<a class="player-ots" href="%s%s.html" target="_blank"><img src="%s"/></a>';
  PLAYER_TEMPLATE = '<span class="%s player-%d">%s%s</span>';
  SCORE_SEPARATOR = '<span class="%s-score">';
  MATCH_TEMPLATE = '<li class="match-outcome-%d"><span class="match-table">#%d</span>%s - %s</li>';

  function HasTeamlist(const APlayer: TVGCPlayer): Boolean;
  begin
    Result := False;
    if Assigned(APlayer) then
      Result := FileExists(TeamlistOutputPath + APlayer.GUID + '.html')
  end;

  function PlayerHtml(const APlayer: TVGCPlayerState; const AIndex: Integer): string;
  var
    LAnchor: string;
    LPlayerCSS: string;
  begin
    LAnchor := '';
    LPlayerCSS := PlayerCSS;
    if HasTeamlist(APlayer.Player) and (AAnchorPath <> '') then
      LAnchor := Format(ANCHOR_TEMPLATE, [AAnchorPath, APlayer.Player.GUID,
      PokemonContext.Config.GetString('TeamlistIconUrl', 'https://images.icon-icons.com/1893/PNG/32/clipboard_120835.png')])
    else
      LPlayerCSS := LPlayerCSS + '-bye';
    Result := Format(PLAYER_TEMPLATE, [LPlayerCSS, AIndex, LAnchor,
      APlayer.AsString(Format(SCORE_SEPARATOR, [LPlayerCSS]), '</span>')]);
  end;
begin
  Result := Format(MATCH_TEMPLATE, [AMatch.Outcome, ATableNumber,
    PlayerHtml(AMatch.P1State, 1), PlayerHtml(AMatch.P2State, 2)]);
end;

procedure TVGCTourOutputHandler.PrintMatch(const AMatch: TVGCMatch);
var
  LTeamlist: string;
  LPlayer1: TVGCPlayer;
  LPlayer2: TVGCPlayer;
  LSwiss1Output: string;
  LSwiss2Output: string;
  LOverlay: string;
begin
  Assert(Assigned(AMatch));

  Log('Printing match...', 3);
  LTeamlist := InsertIncludes(TeamlistHtml, '');

  LPlayer1 := Tournament.Players[AMatch.Player1Id];
  LPlayer2 := Tournament.Players[AMatch.Player2Id];

  SaveTextToFile(P1Output, LPlayer1.ApplyToTemplate(LTeamlist, FPokemonHtml,
    TranslateTeamlist, True));
  SaveTextToFile(P2Output, LPlayer2.ApplyToTemplate(LTeamlist, FPokemonHtml,
    TranslateTeamlist, True));
  Log('Match teamlist printed (%s %s).', [P1Output, P2Output], 4);

  LSwiss1Output := ReplaceText(P1Output, '.html', '_swiss.txt');
  LSwiss2Output := ReplaceText(P2Output, '.html', '_swiss.txt');
  SaveTextToFile(LSwiss1Output, LPlayer1.Score);
  SaveTextToFile(LSwiss2Output, LPlayer2.Score);
  Log('Match swiss score printed (%s %s).', [LSwiss1Output, LSwiss2Output], 4);
  if FOverlayHtml <> '' then
  begin
    LOverlay := FOverlayHtml;
    try
      TAKAppMacrosRegistry.Instance.RegisterExpander('P1', LPlayer1.Data.AsExpander);
      TAKAppMacrosRegistry.Instance.RegisterExpander('P2', LPlayer2.Data.AsExpander);
      TAKAppMacrosRegistry.Instance.Expand(LOverlay);
    finally
      TAKAppMacrosRegistry.Instance.UnregisterExpander('P1');
      TAKAppMacrosRegistry.Instance.UnregisterExpander('P2');
    end;
    SaveTextToFile(OverlayOutput, LOverlay);
    Log('Match overlay printed (%s).', [OverlayOutput], 4);
  end;
  Log('Match printing concluded.', 3);
end;

procedure TVGCTourOutputHandler.PrintPairings(const AIncludePath: string);
begin
  Log('Printing pairings...', 3);
  SaveTextToFile(PairingsOutput, GetPairingsHtmlContent(AIncludePath));
  Log('Pairings printing concluded (%s).', [PairingsOutput], 3);
end;

procedure TVGCTourOutputHandler.PrintPlayerTeamlist(const AOutputPath: string;
  const APlayer: TVGCPlayer; const AAfterPrint: TProc<string, string>);
var
  LHtml: string;
  LFileName: string;
begin
  if not Assigned(APlayer.Team) then
  begin
    Log('Teamlist not found for player %s (%s).', [APlayer.AsString, APlayer.Id], 2);
    Exit;
  end;
  LHtml := APlayer.ApplyToTemplate(TeamlistHtml, FPokemonHtml,
    TranslateTeamlist, False);
  LFileName := APlayer.GUID + '.html';
  SaveTextToFile(AOutputPath + LFileName, InsertIncludes(LHtml, ''));
  Log('Teamlist printed for player %s (%s) "%s".', [APlayer.AsString, APlayer.Id, LFileName], 5);
  if Assigned(AAfterPrint) then
    AAfterPrint(LFileName, LHtml);
end;

procedure TVGCTourOutputHandler.PrintPlayerTeamlists(const AAfterPrint: TProc<string, string>);
var
  LOutputPath: string;
begin
  LOutputPath := TeamlistOutputPath;
  DeleteDirectory(LOutputPath);
  Log('Printing teamlists...', 3);
  Tournament.Players.EnumPlayers(procedure (const APlayer: TVGCPlayer)
    begin
      PrintPlayerTeamlist(LOutputPath, APlayer, AAfterPrint);
    end);
  Log('Teamlist printing concluded.', 3);
end;

procedure TVGCTourOutputHandler.PrintSingleTeamlist(const APlayerId: string;
  const AAfterPrint: TProc<string, string>);
var
  LPlayer: TVGCPlayer;
begin
  if not Tournament.Players.IsIncluded(APlayerId) then
    raise Exception.CreateFmt('Player %s not found in tournament "%s".', [APlayerId, Tournament.Name]);

  LPlayer := Tournament.Players[APlayerId];
  Log('Printing teamlist for player %s (%s)...', [LPlayer.AsString, LPlayer.Id], 3);
  PrintPlayerTeamlist(TeamlistOutputPath, LPlayer, AAfterPrint);
  Log('Teamlist printed for player %s (%s) "%s".', [LPlayer.AsString, LPlayer.Id, LPlayer.GUID + '.html'], 3);
end;

procedure TVGCTourOutputHandler.PrintStandings(const AIncludePath: string);
begin
  Log('Printing standings...', 3);
  SaveTextToFile(StandingsOutput, GetStandingsHtmlContent(AIncludePath));
  Log('Standings printing concluded (%s).', [StandingsOutput], 3);
end;

function TVGCTourOutputHandler.RoundAsHtml(const ARound: TVGCRound;
  const AAnchorPath: string): string;
const
  ROUND_TEMPLATE = '<div id="round-%d-content" class="vgc-round-content">' + sLineBreak +
    '  <div id="round-%0:d-content-title" class="vgc-round-title">Pairings - %s</div>' + sLineBreak +
    '  <ul class="%s" id="round-%0:d-list">' + sLineBreak +'#Matches#' + sLineBreak +
    '  </ul>' + sLineBreak + '</div>';
var
  LResult: string;
begin
  Assert(Assigned(ARound));

  Result := Format(ROUND_TEMPLATE, [ARound.Number, ARound.DisplayName, MatchesCSS]);
  ARound.EnumMatches(procedure (const ATableNumber: Integer; const AMatch: TVGCMatch)
    begin
      if LResult = '' then
        LResult := MatchAsHtml(ATableNumber, AMatch, AAnchorPath)
      else
        LResult := LResult + sLineBreak + MatchAsHtml(ATableNumber, AMatch, AAnchorPath);
    end, True, True);
  Result := ReplaceStr(Result, '#Matches#', IndentLines(LResult, 4));
end;

function TVGCTourOutputHandler.RoundAsHtml(const ARoundIndex: Integer;
  const AAnchorPath: string): string;
begin
  Result := RoundAsHtml(Tournament.Rounds[ARoundIndex], AAnchorPath);
end;

{ TVGCStreamingTournament }

procedure TVGCStreamingTournament.AfterInitialization;
begin
  inherited;
  if Assigned(FRepo) then
    PushTournament;
  if FileExists(RoundsFileName) then
    DeleteFile(RoundsFileName);
end;

procedure TVGCStreamingTournament.AfterUpdate(const AUpdatedRounds: array of Integer;
  const ANewRoundStarted: Boolean);
var
  LLastRoundHtml: string;
  LRoundsHtml: string;

  function GetUpdatedHtml: string;
  var
    I: Integer;
  begin
    FLastRoundHtml := '';
    for I := Low(AUpdatedRounds) to High(AUpdatedRounds) do
    begin
      FLastRoundHtml := OutputHandler.RoundAsHtml(AUpdatedRounds[I], './teamlists/');
      if Result = '' then
        Result := FLastRoundHtml
      else
        Result := Result + sLineBreak + FLastRoundHtml;
      if (I <> High(AUpdatedRounds)) or Rounds[AUpdatedRounds[I]].IsEnded then
        FLastRoundHtml := '';
    end;
  end;
begin
  inherited;
  if ANewRoundStarted then
    OutputHandler.PrintPairings;
  LLastRoundHtml := FLastRoundHtml;
  Logger.Log('Updating tournament file...', 4);
  if FileExists(RoundsFileName) then
  begin
    LRoundsHtml := LoadTextFromFile(RoundsFileName);
    if LLastRoundHtml <> '' then
    // If last round was still open replace it with the updated version of it.
      LRoundsHtml := ReplaceStr(LRoundsHtml, LLastRoundHtml, GetUpdatedHtml)
    else
    // Otherwise just append new updated rounds.
      LRoundsHtml := LRoundsHtml + GetUpdatedHtml;
  end
  else
    LRoundsHtml := GetUpdatedHtml;
  SaveTextToFile(RoundsFileName, LRoundsHtml);
  UpdateTournamentFile;
  Logger.Log('Tournament file updated.', 4);
  if PhaseEnded then
  begin
    OutputHandler.PrintStandings;
    if Assigned(FRepo) then
      TempTextFile(OutputHandler.GetStandingsHtmlContent('./resources/'),
        procedure (const AFileName: string)
        begin
          FRepo.SinglePush(RepoMessage('standings'), AFileName, OutputRepoPath + 'standings.html', RepoBranch);
        end, '.html');
  end;
end;

constructor TVGCStreamingTournament.Create;
var
  LRepoOwner: string;
  LRepoName: string;
begin
  inherited Create;
  FOutputHandler := TVGCTourOutputHandler.Create(Self);
  LRepoOwner := PokemonContext.Config.GetString('GithubRepoOwner');
  LRepoName := PokemonContext.Config.GetString('GithubRepoName');
  if (LRepoOwner <> '') and (LRepoName <> '') then
  begin
    FRepoBranch := PokemonContext.Config.GetString('GithubRepoBranch');
    FRepo := TAKGithubRepoManager.Create;
    FRepo.RepoOwner := LRepoOwner;
    FRepo.RepoName := LRepoName;
    FRepo.TokenFileName := AppPath + 'github_token';
    FRepo.Logger.AddLogOutput(Logger);
  end;
end;

destructor TVGCStreamingTournament.Destroy;
begin
  FreeAndNil(FOutputHandler);
  FreeAndNil(FRepo);
  inherited;
end;

procedure TVGCStreamingTournament.ExpandTournamentMacros(var AString: string);
begin
  AString := ReplaceText(AString, '{TournamentName}', Name);
end;

function TVGCStreamingTournament.GetOutputRepoPath: string;
begin
  Result := PokemonContext.Config.GetString('GithubOutputPath', '{TournamentName}');
  ExpandTournamentMacros(Result);
  if Result[High(Result)] <> '/' then
    Result := Result + '/';
end;

function TVGCStreamingTournament.GetResourcesRepoPath: string;
begin
  Result := OutputRepoPath + 'resources/';
end;

function TVGCStreamingTournament.GetRoundsFileName: string;
begin
  Result := OutputHandler.TeamlistOutputPath + '..' + PathDelim + 'rounds_content.html';
end;

function TVGCStreamingTournament.GetTeamlistRepoPath: string;
begin
  Result := OutputRepoPath + 'teamlists/';
end;

function TVGCStreamingTournament.GetTourFileName: string;
begin
  Result := OutputHandler.TeamlistOutputPath + '..' + PathDelim + 'tournament.html';
end;

procedure TVGCStreamingTournament.PrintMatch(const AMatch: TVGCMatch);
begin
  Assert(Assigned(AMatch));

  OutputHandler.PrintMatch(AMatch);
end;

procedure TVGCStreamingTournament.PrintPlayerTeamlists;
var
  LTmp: string;
begin
  if Assigned(FRepo) then
  begin
    LTmp := IncludeTrailingPathDelimiter(OutputHandler.TeamlistOutputPath + 'tmp');
    CreateDirectory(LTmp);
    try
      FRepo.BeginCommit(RepoMessage('teamlist'), RepoBranch);
      try
        OutputHandler.PrintPlayerTeamlists(procedure (AFileName, AHtml: string)
        var
          LFileName: string;
        begin
          LFileName := LTmp + AFileName;
          SaveTextToFile(LFileName, OutputHandler.InsertIncludes(AHtml, '../resources/'));
          FRepo.AddToCommit(raPush, LFileName, TeamlistRepoPath);
        end);
        FRepo.SendCommit;
      except
        FRepo.CancelCommit;
        raise;
      end;
    finally
      DeleteDirectory(LTmp);
    end;
  end
  else
    OutputHandler.PrintPlayerTeamlists(nil);
end;

procedure TVGCStreamingTournament.PrintSingleTeamlist(const APlayerId: string);
var
  LTmp: string;
begin
  if Assigned(FRepo) then
  begin
    LTmp := IncludeTrailingPathDelimiter(OutputHandler.TeamlistOutputPath + 'tmp');
    CreateDirectory(LTmp);
    try
      OutputHandler.PrintSingleTeamlist(APlayerId, procedure (AFileName, AHtml: string)
      var
        LFileName: string;
      begin
        LFileName := LTmp + AFileName;
        SaveTextToFile(LFileName, OutputHandler.InsertIncludes(AHtml, '../resources/'));

        FRepo.SinglePush(RepoMessage('teamlist'), LFileName, TeamlistRepoPath, '');
      end);
    finally
      DeleteDirectory(LTmp);
    end;
  end
end;

procedure TVGCStreamingTournament.PushTournament;
var
  LFiles: TArray<string>;
  LFile: string;
begin
  Assert(Assigned(FRepo));

  LFiles := OutputHandler.GetIncludes('Github').Split([' ']);
  FRepo.BeginCommit(RepoMessage('resources'), RepoBranch);
  try
    FRepo.AddToCommit(raDelete, '', OutputRepoPath);
    for LFile in LFiles do
      if FileExists(LFile) then
        FRepo.AddToCommit(raPush, LFile, ResourcesRepoPath);
    FRepo.SendCommit;
  except
    FRepo.CancelCommit;
    raise;
  end;
end;

function TVGCStreamingTournament.RepoMessage(const AUploadType: string): string;
begin
  Result := Format(REPO_MESSAGE, [AUploadType, Name])
end;

procedure TVGCStreamingTournament.UpdateTournamentFile;
var
  LTourHtml: string;
begin
  if FTourHtml = '' then
    FTourHtml := OutputHandler.InsertIncludes(OutputHandler.TournamentHtml, './resources/');

  LTourHtml := ReplaceAndIndent(FTourHtml, '%RoundsHeader%', OutputHandler.RoundsHeaderHtml);
  LTourHtml := ReplaceAndIndent(LTourHtml, '%RoundsContent%', LoadTextFromFile(RoundsFileName));
  SaveTextToFile(TourFileName, LTourHtml);
  if Assigned(FRepo) then
    FRepo.SinglePush(RepoMessage('pairings'), TourFileName, OutputRepoPath + 'index.html', RepoBranch);
end;

end.
