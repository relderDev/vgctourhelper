unit VGCTournament;

interface

uses
  Classes, Generics.Collections, Xml.XMLIntf,
  AK.Base, AK.Indy,
  VGCPlayer;

type
  TVGCPlayerState = record
  public
    Player: TVGCPlayer;
    Wins: Integer;
    Losses: Integer;
    procedure Assign(const APlayerState: TVGCPlayerState);
    function AsString(const ABeforeScore: string = ' '; const AAfterScore: string = ''): string;
    constructor Create(const APlayer: TVGCPlayer);
    constructor Clone(const APlayerState: TVGCPlayerState);
  end;

  TVGCMatch = class
  strict private
    FPlayer1: TVGCPlayerState;
    FPlayer2: TVGCPlayerState;
    FOutcome: Integer;
    procedure SetOutcome(const AValue: Integer);
    function GetPlayer1Id: string;
    function GetPlayer2Id: string;
  public
    property P1State: TVGCPlayerState read FPlayer1;
    property P2State: TVGCPlayerState read FPlayer2;
    property Player1Id: string read GetPlayer1Id;
    property Player2Id: string read GetPlayer2Id;
    property Outcome: Integer read FOutcome write SetOutcome;
    procedure Switch;
    function AsString(const AShowOutcome: Boolean): string;
    function AsJSONString(const ATableNumber: Integer): string;
    constructor Create(const APlayer1, APlayer2: TVGCPlayer);
  end;

  TVGCMatchProc = reference to procedure (const ATableNumber: Integer; const AMatch: TVGCMatch);

  TVGCRound = class
  strict private
    FMatches: TObjectDictionary<Integer, TVGCMatch>;
    FRoundNumber: Integer;
    FIsTopCut: Boolean;
    function GetByeMatchCount: Integer;
    function FindMatch(const ATableNumber: Integer): TVGCMatch; overload;
    function FindMatch(const APlayerId: string; out ATableNumber: Integer): TVGCMatch; overload;
    function FindMatch(const APlayerId: string): TVGCMatch; overload;
    function InternalFindMatch(const AKey: Variant): TVGCMatch;
    function GetIsEnded: Boolean;
    function GetIsTheFinal: Boolean;
    function GetDisplayName: string;
  private
    property IsTopCut: Boolean read FIsTopCut write FIsTopCut;
  public
    property Matches[const ATableNumberOrPlayerId: Variant]: TVGCMatch read InternalFindMatch; default;
    property Number: Integer read FRoundNumber;
    property IsEnded: Boolean read GetIsEnded;
    property IsTheFinal: Boolean read GetIsTheFinal;
    property DisplayName: string read GetDisplayName;
    procedure SetMatch(const ATableNumber: Integer; const APlayer1, APlayer2: TVGCPlayer);
    procedure SetWinner(const APlayerId: string);
    procedure EnumMatches(const AProc: TVGCMatchProc; const AIncludeByes: Boolean;
      const ASorted: Boolean = True);
    function AsString(const AShowOutcomes: Boolean = False): string;
    function AsJSONString: string;
    constructor Create(const ARoundNumber: Integer);
    destructor Destroy; override;
  end;

  TVGCRounds = array of TVGCRound;

  TVGCTournament = class(TAKBase)
  strict private
    FName: string;
    FIsMajor: Boolean;
    FPlayers: TVGCPlayers;
    FSwissRounds: Integer;
    FCut: Integer;
    FRounds: TVGCRounds;
    FRoundCount: Integer;
    FMainXmlFileName: string;
    FPodIndex: Integer;
    FWinnerId: string;
    FInitialized: Boolean;
    const
      ERR_NOT_INITIALIZED = 'Tournament has not started yet. Call Initialize() or set a valid MainXmlFileName to start it.';
      ERR_ALREADY_INITIALIZED = 'Tournament has already started. The active tournament run must be ended before starting a new one.';
      ERR_XML_NOT_FOUND = 'XML file not found (%s).';
      ERR_MAIN_XML_REQUIRED = 'XML file argument required for each round in manual mode.';
      ERR_ROUND_NOT_STARTED = 'Round %d has not started yet.';
    procedure AddPlayerFromXmlNode(const ANode: IXMLNode);
    procedure SetSwissRounds;
    procedure SetCutThreshold(const ACutInfo: IXMLNode);
    procedure AddMatch(const ARound: TVGCRound; const AMatch: IXMLNode);
    procedure AddPokepaste(const APlayerId, APokepaste: string;
      const AHttpClient: TAKIndyHttp);
    procedure FreeRounds;
    procedure SetMainXmlFileName(const AValue: string);
    function CreateNewRound(const ARoundNumber: Integer; const ARoundNode: IXMLNode): TVGCRound;
    function UpdateRounds(const ARoundsNode: IXMLNode): Boolean;
    function GetHasDay2: Boolean;
    function GetDay2RoundCount: Integer;
    function GetPlayers: TVGCPlayers;
    function GetRound(const AIndex: Integer): TVGCRound;
    function GetLastRound: TVGCRound;
    function GetPhaseEnded: Boolean;
    function GetPairings(const AShowOutcomes: Boolean): string;
    function GetWinner: TVGCPlayer;
  strict protected
    property HasDay2: Boolean read GetHasDay2;
    property Day2RoundCount: Integer read GetDay2RoundCount;
    procedure AfterInitialization; virtual;

    /// <summary>
    ///  Sets the score of all ended matches found in the given XML node for the
    ///  last round. Returns true only if all round matches are then concluded.
    /// </summary>
    function EndRound(const ARoundNumber: Integer; ANode: IXMLNode): Boolean;

    procedure AfterUpdate(const AUpdatedRounds: array of Integer;
      const ANewRoundStarted: Boolean); virtual;
  public
    property Name: string read FName write FName;
    property IsMajor: Boolean read FIsMajor write FIsMajor;
    property SwissRounds: Integer read FSwissRounds;
    property Players: TVGCPlayers read GetPlayers;
    property Rounds[const AIndex: Integer]: TVGCRound read GetRound; default;
    property LastRound: TVGCRound read GetLastRound;
    property PhaseEnded: Boolean read GetPhaseEnded;
    property RoundCount: Integer read FRoundCount;
    property MainXmlFileName: string read FMainXmlFileName write SetMainXmlFileName;
    property PodIndex: Integer read FPodIndex write FPodIndex;
    property Pairings[const AShowOutcomes: Boolean]: string read GetPairings;
    property WinnerId: string read FWinnerId;
    property Winner: TVGCPlayer read GetWinner;

    /// <summary>
    ///  Loads configuration and players for the tournament.
    /// </summary>
    procedure Initialize(const AXmlFileName: string);

    /// <summary>
    ///  Ends the current running tournament, if any.
    /// </summary>
    procedure EndTournament;

    /// <summary>
    ///  Ends the current running tournament, if any, and starts a new one by
    ///  setting the given XML file as the new main XML file.
    /// </summary>
    /// <remarks>
    ///  Do not use this method to restart a tournament in manual mode: call
    ///  EndTournament and Initialize instead.
    /// </remarks>
    procedure Restart(const AXmlFileName: string); overload;

    /// <summary>
    ///  Ends the current running tournament, if any, and starts a new one using
    ///  the same main XML file.
    /// </summary>
    procedure Restart; overload;

    /// <summary>
    ///  Manual add a single pokepaste. Useful for mid-tournament adds or edits.
    /// </summary>
    procedure AddSinglePokepaste(const APlayerId, APokepaste: string);

    /// <summary>
    ///  Loads all the pokepastes for the players from a CSV file.
    /// </summary>
    procedure AddPokepasteCSV(const ACSVFileName: string);

    /// <summary>
    ///  Loads all the pokepastes in the JSON array returned by the GET request
    ///  that is sent to the given url.
    /// </summary>
    procedure AddPokepasteJSON(const AUrl: string);

    /// <summary>
    ///  Sets the winner of the round's corresponding match.
    /// </summary>
    procedure EndRoundMatch(const ARoundNumber: Integer; const AWinnerPlayerId: string); virtual;

    /// <summary>
    ///  The main method. Call this to load the XML file and apply any update to
    ///  the tournament. Manual mode. Returns true when a new round has started.
    /// </summary>
    function Update(const AXmlFileName: string): Boolean; overload;

    /// <summary>
    ///  The main method. Call this to load the XML file and apply any update to
    ///  the tournament. Uses the main XML file. Returns true when a new round
    ///  has started.
    /// </summary>
    function Update: Boolean; overload;

    function IsCut(const AIndex: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils, StrUtils, Math, Variants, JSON, Xml.XMLDoc,
  AK.Data, AK.Utils,
  Pokemon.Context;

{ TVGCPlayerState }

procedure TVGCPlayerState.Assign(const APlayerState: TVGCPlayerState);
begin
  Assert(Assigned(APlayerState.Player));

  Player := APlayerState.Player;
  Wins := APlayerState.Wins;
  Losses := APlayerState.Losses;
end;

function TVGCPlayerState.AsString(const ABeforeScore, AAfterScore: string): string;
begin
  if Assigned(Player) then
    Result := Format('%s%s(%d-%d)%s', [Player.AsString, ABeforeScore, Wins, Losses, AAfterScore])
  else
    Result := 'BYE';
end;

constructor TVGCPlayerState.Clone(const APlayerState: TVGCPlayerState);
begin
  Assign(APlayerState);
end;

constructor TVGCPlayerState.Create(const APlayer: TVGCPlayer);
begin
  if Assigned(APlayer) then
  begin
    Player := APlayer;
    Wins := APlayer.CurrentWins;
    Losses := APlayer.CurrentLosses;
  end
  else
  begin
    // This is a BYE
    Player := nil;
    Wins := 0;
    Losses := 0;
  end;
end;

{ TVGCMatch }

function TVGCMatch.AsJSONString(const ATableNumber: Integer): string;
var
  LIdStr: string;
begin
  if FOutcome = 5 then
  begin
    Result := Format('%s - BYE', [FPlayer1.AsString]);
    LIdStr := Format('"player1GUID": "%s"', [FPlayer1.Player.GUID]);
  end
  else
  begin
    Result := Format('%s - %s', [FPlayer1.AsString, FPlayer2.AsString]);
    LIdStr := Format('"player1GUID": "%s", "player2GUID": "%s"',
      [FPlayer1.Player.GUID, FPlayer2.Player.GUID]);
  end;
  Result := Format('{ "table": %d, "text": "%s", "outcome": %d, %s }',
    [ATableNumber, Result, FOutcome, LIdStr]);
end;

function TVGCMatch.AsString(const AShowOutcome: Boolean): string;
begin
  if FOutcome = 5 then // On BYEs Player1 must be always the assigned one
    Result := Format('%s - BYE', [FPlayer1.AsString])
  else
    Result := Format('[1] %s - [2] %s', [FPlayer1.AsString, FPlayer2.AsString]);
  if AShowOutcome then
    Result := Format('%s {%d}', [Result, FOutcome]);
end;

constructor TVGCMatch.Create(const APlayer1, APlayer2: TVGCPlayer);
begin
  Assert(Assigned(APlayer1) or Assigned(APlayer2));

  FPlayer1 := TVGCPlayerState.Create(APlayer1);
  FPlayer2 := TVGCPlayerState.Create(APlayer2);
  if Assigned(APlayer1) and Assigned(APlayer2) then
    FOutcome := 0
  else
  begin
    FOutcome := 5;
    if not Assigned(APlayer1) then
      APlayer2.Win(nil)
    else
      APlayer1.Win(nil);
  end;
end;

function TVGCMatch.GetPlayer1Id: string;
begin
  if Assigned(FPlayer1.Player) then
    Result := FPlayer1.Player.Id;
end;

function TVGCMatch.GetPlayer2Id: string;
begin
  if Assigned(FPlayer2.Player) then
    Result := FPlayer2.Player.Id;
end;

procedure TVGCMatch.SetOutcome(const AValue: Integer);
begin
  // BYEs are determined on the start of a match, we must account only for W/L.
  case AValue of
    1:
    begin
      FPlayer1.Player.Win(FPlayer2.Player);
      FPlayer2.Player.Loss(FPlayer1.Player);
    end;
    2:
    begin
      FPlayer1.Player.Loss(FPlayer2.Player);
      FPlayer2.Player.Win(FPlayer1.Player);
    end
    else
      raise Exception.CreateFmt('Invalid match outcome "%d"', [AValue]);
  end;
  FOutcome := AValue;
end;

procedure TVGCMatch.Switch;
var
  LTemp: TVGCPlayerState;
begin
  case FOutcome of
    1: FOutcome := 2;
    2: FOutcome := 1;
    5: Exit; // No switch for BYE rounds.
  end;

  LTemp := TVGCPlayerState.Clone(FPlayer1);
  FPlayer1.Assign(FPlayer2);
  FPlayer2.Assign(LTemp);
end;

{ TVGCRound }

function TVGCRound.AsJSONString: string;
var
  LSorted: TList<Integer>;
  LTable: Integer;
begin
  Result := '';
  LSorted := TList<Integer>.Create(FMatches.Keys);
  try
    LSorted.Sort;
    for LTable in LSorted do
      if Result = '' then
        Result := FMatches[LTable].AsJSONString(LTable)
      else
        Result := Result + ', ' + FMatches[LTable].AsJSONString(LTable);
  finally
    FreeAndNil(LSorted);
  end;
  Result := Format('{ "round": %d, "matches": [%s] }', [FRoundNumber, Result]);
end;

function TVGCRound.AsString(const AShowOutcomes: Boolean): string;
var
  LSorted: TList<Integer>;
  LTable: Integer;

  function MatchString(const ATable: Integer): string;
  begin
    Result := Format('[Table %d] %s',
      [ATable, FMatches[ATable].AsString(AShowOutcomes)]);
  end;
begin
  Result := DisplayName;
  LSorted := TList<Integer>.Create(FMatches.Keys);
  try
    LSorted.Sort;
    for LTable in LSorted do
      Result := Result + sLineBreak + MatchString(LTable);
  finally
    FreeAndNil(LSorted);
  end;
end;

constructor TVGCRound.Create(const ARoundNumber: Integer);
begin
  FMatches := TObjectDictionary<Integer, TVGCMatch>.Create([doOwnsValues]);
  FRoundNumber := ARoundNumber;
  FIsTopCut := False;
end;

destructor TVGCRound.Destroy;
begin
  FreeAndNil(FMatches);
  inherited;
end;

procedure TVGCRound.EnumMatches(const AProc: TVGCMatchProc; const AIncludeByes, ASorted: Boolean);
var
  LList: TList<Integer>;
  LTable: Integer;
begin
  Assert(Assigned(AProc));
  LList := TList<Integer>.Create(FMatches.Keys);
  try
    if ASorted then
      LList.Sort;
    for LTable in LList do
      if AIncludeByes or (FMatches[LTable].Outcome <> 5) then
        AProc(LTable, FMatches[LTable]);
  finally
    FreeAndNil(LList);
  end;
end;

function TVGCRound.FindMatch(const ATableNumber: Integer): TVGCMatch;
begin
  Result := nil;
  if FMatches.ContainsKey(ATableNumber) then
    Result := FMatches[ATableNumber];
end;

function TVGCRound.FindMatch(const APlayerId: string; out ATableNumber: Integer): TVGCMatch;
var
  LKey: Integer;
  LMatch: TVGCMatch;
begin
  Assert(APlayerId <> '');

  Result := nil;
  for LKey in FMatches.Keys do
  begin
    LMatch := FMatches[LKey];
    ATableNumber := LKey;
    if MatchText(APlayerId, [LMatch.Player1Id, LMatch.Player2Id]) then
      Exit(LMatch);
  end;
  ATableNumber := -1;
end;

function TVGCRound.FindMatch(const APlayerId: string): TVGCMatch;
var
  LThrow: Integer;
begin
  Result := FindMatch(APlayerId, LThrow);
end;

function TVGCRound.GetByeMatchCount: Integer;
var
  LMatch: TVGCMatch;
begin
  Result := 0;
  for LMatch in FMatches.Values do
    if LMatch.Outcome = 5 then
      Inc(Result);
end;

function TVGCRound.GetDisplayName: string;
var
  LByeCount: Integer;
begin
  if IsTopCut then
  begin
    LByeCount := GetByeMatchCount;
    if LByeCount <> 0 then
      Result := 'TopCut'
    else if IsTheFinal then
      Result := 'Final'
    else
      Result := Format('Top %d', [FMatches.Count * 2]);
  end
  else
    Result := Format('Round %d', [Number + 1]);
end;

function TVGCRound.GetIsEnded: Boolean;
var
  LMatch: TVGCMatch;
begin
  Result := True;
  for LMatch in FMatches.Values do
    if LMatch.Outcome = 0 then
      Exit(False);
end;

function TVGCRound.GetIsTheFinal: Boolean;
begin
  Result := FMatches.Count = 1
end;

function TVGCRound.InternalFindMatch(const AKey: Variant): TVGCMatch;
var
  LThrow: Integer;
begin
  if VarIsStr(AKey) then
    Result := FindMatch(VarToStr(AKey), LThrow)
  else if VarIsOrdinal(AKey) then
    Result := FindMatch(Integer(AKey))
  else
    raise Exception.Create('Invalid variant type given.');
end;

procedure TVGCRound.SetMatch(const ATableNumber: Integer; const APlayer1,
  APlayer2: TVGCPlayer);
begin
  // Matches do always overwrite - could be for manual correction or anything.
  if FMatches.ContainsKey(ATableNumber) then
    FMatches.Remove(ATableNumber);
  FMatches.Add(ATableNumber, TVGCMatch.Create(APlayer1, APlayer2));
end;

procedure TVGCRound.SetWinner(const APlayerId: string);
var
  LMatch: TVGCMatch;
  LScore: Integer;
begin
  LMatch := FindMatch(APlayerId);
  Assert(Assigned(LMatch));

  if LMatch.Player1Id = APlayerId then
    LScore := 1
  else
    LScore := 2;
  LMatch.Outcome := LScore;
end;

{ TVGCTournament }

procedure TVGCTournament.AddPokepaste(const APlayerId, APokepaste: string;
  const AHttpClient: TAKIndyHttp);
var
  LText: string;
  LJSON: TJSONObject;
  LPlayer: TVGCPlayer;
begin
  Assert(PokemonContext.IsAllOpen);

  if not FPlayers.IsIncluded(APlayerId) then
    Exit;
  LText := APokepaste;
  if IsUrl(LText) then
  begin
    Assert(Assigned(AHttpClient));
    Logger.Log('Adding pokepaste from URL "%s".', [LText], 4);
    if not LText.EndsWith('/json') then
      LText := LText + '/json';
    LJSON := TJSONObject.ParseJSONValue(AHttpClient.Get(LText)) as TJSONObject;
    try
      LText := LJSON.GetValue<string>('paste');
    finally
      FreeAndNil(LJSON);
    end;
  end;
  LPlayer := FPlayers[APlayerId];
  Logger.Log('Setting the paste fot player %s (%s).', [LPlayer.AsString, LPlayer.GUID], 4);
  LPlayer.PokepasteText := LText;
  Logger.Log('Paste successfully set.', 4);
end;

procedure TVGCTournament.AddPokepasteCSV(const ACSVFileName: string);
var
  LData: TAKDynRecordCollectionCSV;
  LIdFieldName: string;
  LPasteFieldName: string;
  LHttp: TAKIndyHttp;
  I: Integer;
begin
  Assert(FInitialized, ERR_NOT_INITIALIZED);

  LData := TAKDynRecordCollectionCSV.Create;
  try
    if not PokemonContext.IsAllOpen then
    begin
      Logger.Log('Opening pokemon data...', 3);
      PokemonContext.Open;
      Logger.Log('All pokemon data loaded.', 3);
    end;
    LData.Config['ColumnDelimiter'] := PokemonContext.Config['ColumnDelimiter'];
    LData.Config['TextDelimiter'] := PokemonContext.Config['TextDelimiter'];
    LData.Config['FirstRowIsHeader'] := PokemonContext.Config['FirstRowIsHeader'];
    LIdFieldName := PokemonContext.Config.GetString('PlayerIdFieldName', 'PlayerId');
    LPasteFieldName := PokemonContext.Config.GetString('PokepasteFieldName', 'Pokepaste');
    Logger.Log('Loading pastes from the CSV file "%s".', [ACSVFileName], 3);
    LData.LoadFromFile(ACSVFileName);
    LHttp := TAKIndyHttp.Create(nil);
    try
      for I := 0 to LData.Count - 1 do
        AddPokepaste(LData[I].GetString(LIdFieldName),
          LData[I].GetString(LPasteFieldName), LHttp);
      Logger.Log('Pastes loaded.', 3);
    finally
      FreeAndNil(LHttp);
    end;
  finally
    FreeAndNil(LData);
    PokemonContext.Close;
    Logger.Log('Pokemon data closed.', 3);
  end;
end;

procedure TVGCTournament.AddPokepasteJSON(const AUrl: string);
var
  LData: TAKDynRecordCollectionJSON;
  LIdFieldName: string;
  LPasteFieldName: string;
  LHttp: TAKIndyHttp;
  I: Integer;
begin
  Assert(FInitialized, ERR_NOT_INITIALIZED);

  LData := TAKDynRecordCollectionJSON.Create;
  try
    if not PokemonContext.IsAllOpen then
    begin
      Logger.Log('Opening pokemon data...', 3);
      PokemonContext.Open;
      Logger.Log('All pokemon data loaded.', 3);
    end;
    LData.Config['HeaderFromFirstRecord'] := PokemonContext.Config['HeaderFromFirstRecord'];
    LIdFieldName := PokemonContext.Config.GetString('PlayerIdFieldName', 'PlayerId');
    LPasteFieldName := PokemonContext.Config.GetString('PokepasteFieldName', 'Pokepaste');
    Assert(IsUrl(AUrl));
    LHttp := TAKIndyHttp.Create(nil);
    try
      Logger.Log('Loading pastes from JSON returned at the URL "%s".', [AUrl], 3);
      LData.LoadData(LHttp.Get(AUrl));
      for I := 0 to LData.Count - 1 do
        AddPokepaste(LData[I].GetString(LIdFieldName),
          LData[I].GetString(LPasteFieldName), LHttp);
      Logger.Log('Pastes loaded.', 3);
    finally
      FreeAndNil(LHttp);
    end;
  finally
    FreeAndNil(LData);
    PokemonContext.Close;
  end;
end;

procedure TVGCTournament.AddSinglePokepaste(const APlayerId, APokepaste: string);
var
  LHttp: TAKIndyHttp;
  LText: string;
  LJSON: TJSONObject;
  LCloseAfter: Boolean;
  LPlayer: TVGCPlayer;
begin
  Assert(FInitialized, ERR_NOT_INITIALIZED);
  if not FPlayers.IsIncluded(APlayerId) then
    raise Exception.CreateFmt('Player "%s" not found in tournament %s.', [APlayerId, Name]);

  LText := APokepaste;
  if IsUrl(LText) then
  begin
    Logger.Log('Adding single pokepaste from URL "%s".', [LText], 4);
    if not LText.EndsWith('/json') then
      LText := LText + '/json';
    LHttp := TAKIndyHttp.Create(nil);
    try
      LText := LHttp.Get(LText);
      LJSON := TJSONObject.ParseJSONValue(LText) as TJSONObject;
      try
        LText := LJSON.GetValue<string>('paste');
      finally
        FreeAndNil(LJSON);
      end;
    finally
      FreeAndNil(LHttp);
    end;
  end;
  LCloseAfter := not PokemonContext.IsAllOpen;
  if LCloseAfter then
  begin
    Logger.Log('Opening pokemon data...', 3);
    PokemonContext.Open;
    Logger.Log('All pokemon data loaded.', 3);
  end;
  try
    LPlayer := FPlayers[APlayerId];
    Logger.Log('Setting the paste fot player %s (%s).', [LPlayer.AsString, LPlayer.GUID], 4);
    LPlayer.PokepasteText := LText;
    Logger.Log('Paste successfully set.', 4)
  finally
    if LCloseAfter then
    begin
      PokemonContext.Close;
      Logger.Log('Pokemon data closed.', 3);
    end;
  end;
end;


procedure TVGCTournament.AfterInitialization;
begin
end;

procedure TVGCTournament.AfterUpdate(const AUpdatedRounds: array of Integer;
  const ANewRoundStarted: Boolean);
begin
end;

procedure TVGCTournament.AddMatch(const ARound: TVGCRound; const AMatch: IXMLNode);
var
  LPlayer1Id: string;
  LPlayer2Id: string;
begin
  Assert(Assigned(ARound));
  Assert(Assigned(AMatch));

  if XMLNodeHasChild(AMatch, 'player1') then
     LPlayer1Id := AMatch.ChildNodes['player1'].Attributes['userid']
  else
    LPlayer1Id := AMatch.ChildNodes['player'].Attributes['userid'];
  Assert(LPlayer1Id <> '');
  LPlayer2Id := AKVarToString(AMatch.ChildNodes['player2'].Attributes['userid']);
  ARound.SetMatch(AMatch.ChildValues['tablenumber'],
    FPlayers[LPlayer1Id], FPlayers.FindPlayer(LPlayer2Id));
end;

procedure TVGCTournament.AddPlayerFromXmlNode(const ANode: IXMLNode);
var
  LPlayer: TVGCPlayer;
begin
  LPlayer := TVGCPlayer.Create;
  LPlayer.ReadFromXmlNode(ANode);
  FPlayers.AddPlayer(LPlayer);
end;

constructor TVGCTournament.Create;
begin
  inherited Create;
  FIsMajor := False;
  FPlayers := TVGCPlayers.Create;
  FSwissRounds := -1;
  FRoundCount := 0;
  FPodIndex := -1;
  FInitialized := False;
end;

function TVGCTournament.CreateNewRound(const ARoundNumber: Integer; const ARoundNode: IXMLNode): TVGCRound;
var
  LMatchesNode: IXMLNode;
  I: Integer;
begin
  Assert(Assigned(ARoundNode));

  Result := TVGCRound.Create(ARoundNumber);
  try
    LMatchesNode := ARoundNode.ChildNodes['matches'];
    for I := 0 to LMatchesNode.ChildNodes.Count - 1 do
      AddMatch(Result, LMatchesNode.ChildNodes[I]);
    Result.IsTopCut := ARoundNode.Attributes['type'] = 1;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

destructor TVGCTournament.Destroy;
begin
  EndTournament;
  FreeAndNil(FPlayers);
  inherited;
end;

function TVGCTournament.EndRound(const ARoundNumber: Integer; ANode: IXMLNode): Boolean;
var
  LMatches: IXMLNodeList;
  LScore: Integer;
  I: Integer;
begin
  Assert(Assigned(ANode));

  LMatches := ANode.ChildNodes['matches'].ChildNodes;
  for I := 0 to LMatches.Count - 1 do
  begin
    LScore := LMatches[I].Attributes['outcome'];
    case LScore of
      1: EndRoundMatch(ARoundNumber, LMatches[I].ChildNodes['player1'].Attributes['userid']);
      2: EndRoundMatch(ARoundNumber, LMatches[I].ChildNodes['player2'].Attributes['userid']);
      0: ; // Match not ended.
      5: ; // Match has a BYE - already accounted for.
      else raise Exception.CreateFmt('Unknown match outcome "%d".', [LScore]);
    end;
  end;
  Result := Rounds[ARoundNumber].IsEnded;
end;

procedure TVGCTournament.EndRoundMatch(const ARoundNumber: Integer; const AWinnerPlayerId: string);
begin
  Rounds[ARoundNumber].SetWinner(AWinnerPlayerId);
  if Rounds[ARoundNumber].IsTheFinal then
    FWinnerId := AWinnerPlayerId;
end;

procedure TVGCTournament.EndTournament;
begin
  FreeRounds;
  FPlayers.Clear;
  FInitialized := False;
end;

procedure TVGCTournament.FreeRounds;
var
  I: Integer;
begin
  for I := 0 to High(FRounds) do
    FreeAndNil(FRounds[I]);
  SetLength(FRounds, 0);
end;

function TVGCTournament.GetDay2RoundCount: Integer;
begin
  Assert(HasDay2);

  if FPlayers.Count < 513 then
    Result := 2
  else if FPlayers.Count < 1025  then
    Result := 3
  else if FPlayers.Count < 4097 then
    Result := 4
  else
    Result := 5;
end;

function TVGCTournament.GetHasDay2: Boolean;
begin
  Result := IsMajor and (FPlayers.Count > 64);
end;

function TVGCTournament.GetLastRound: TVGCRound;
begin
  Result := nil;
  if FRoundCount > 0 then
    Result := FRounds[FRoundCount - 1];
end;

function TVGCTournament.GetPairings(const AShowOutcomes: Boolean): string;
begin
  Assert(Assigned(LastRound));

  Result := LastRound.AsString(AShowOutcomes);
end;

function TVGCTournament.GetPhaseEnded: Boolean;
begin
  if (not Assigned(LastRound)) or (not LastRound.IsEnded) then
    Exit(False);
  Result := (LastRound.Number = SwissRounds - 1) or (FWinnerId <> '');
  if HasDay2 and not Result then
    Result := LastRound.Number = SwissRounds - Day2RoundCount - 1;
end;

function TVGCTournament.GetPlayers: TVGCPlayers;
begin
  Assert(FInitialized, ERR_NOT_INITIALIZED);

  Result := FPlayers;
end;

function TVGCTournament.GetRound(const AIndex: Integer): TVGCRound;
begin
  Assert(AIndex < FRoundCount, Format(ERR_ROUND_NOT_STARTED, [AIndex]));

  Result := FRounds[AIndex];
  Assert(Assigned(FRounds));
end;

function TVGCTournament.GetWinner: TVGCPlayer;
begin
  Result := nil;
  if FWinnerId <> '' then
    Result := FPlayers[FWinnerId];
end;

procedure TVGCTournament.Initialize(const AXmlFileName: string);
var
  LXml: IXMLDocument;
  LPlayersNode: IXMLNode;
  I: Integer;
begin
  Assert(not FInitialized, ERR_ALREADY_INITIALIZED);
  Assert(FileExists(AXmlFileName), Format(ERR_XML_NOT_FOUND, [AXmlFileName]));

  Logger.Log('Initializing tournament with file "%s".', [AXmlFileName], 3);
  LXml := TXMLDocument.Create(nil);
  LXml.LoadFromFile(AXmlFileName);
  LXml.Active := True;
  if Name = '' then
    Name := LXml.DocumentElement.ChildNodes['data'].ChildValues['name'];
  if Name = '' then
    Name := 'VGCTournament_' + FormatDateTime('yyyy-mm-dd', Now);
  Logger.Log('Adding players...', 4);
  LPlayersNode := LXml.DocumentElement.ChildNodes['players'];
  for I := 0 to LPlayersNode.ChildNodes.Count - 1 do
    AddPlayerFromXmlNode(LPlayersNode.ChildNodes[I]);
  Logger.Log('Players added. Setting swiss rounds...', 4);
  SetSwissRounds;
  SetCutThreshold(LXml.DocumentElement.ChildNodes['finalsoptions'].ChildNodes['categorycut']);
  Logger.Log('Swiss rounds set: %d, cut %d.', [FSwissRounds, FCut], 4);
  FInitialized := True;
  AfterInitialization;
  Logger.Log('Initialization complete.', 3);
end;

function TVGCTournament.IsCut(const AIndex: Integer): Boolean;
begin
  Assert(Assigned(LastRound));

  Result := False;
  // Highlight cut only when a phase is ended.
  if not PhaseEnded then
    Exit;

  if IsMajor then
  begin
    // { TODO: implement asymmetrical topcut and day2 cut }
  end
  else
    Result := AIndex < FCut; // AIndex is 0-based (top 4: 0, 1, 2, 3 are in).
end;

procedure TVGCTournament.Restart(const AXmlFileName: string);
begin
  EndTournament;
  MainXmlFileName := AXmlFileName;
end;

procedure TVGCTournament.Restart;
begin
  Restart(FMainXmlFileName);
end;

procedure TVGCTournament.SetCutThreshold(const ACutInfo: IXMLNode);
begin
  FCut := ACutInfo.ChildValues['cut'];
end;

procedure TVGCTournament.SetMainXmlFileName(const AValue: string);
var
  LOldValue: string;
begin
  LOldValue := FMainXmlFileName;
  FMainXmlFileName := AValue;
  try
    if not FInitialized then
      Initialize(FMainXmlFileName);
  except
    FMainXmlFileName := LOldValue;
    raise;
  end;
end;

procedure TVGCTournament.SetSwissRounds;
begin
  if FPlayers.Count < 9 then
     FSwissRounds := 3
  else
    FSwissRounds := Ceil(Log2(Double(FPlayers.Count)));
  if IsMajor and (FPlayers.Count > 64) then
    Inc(FSwissRounds);
end;

function TVGCTournament.Update(const AXmlFileName: string): Boolean;
var
  LXml: IXMLDocument;
  LPodsNode: IXMLNode;
begin
  Assert(FInitialized, ERR_NOT_INITIALIZED);
  Assert(FileExists(AXmlFileName), Format(ERR_XML_NOT_FOUND, [AXmlFileName]));

  // Parse XML file and check configuration.
  LXml := TXMLDocument.Create(nil);
  LXml.LoadFromFile(AXmlFileName);
  LXml.Active := True;
  LPodsNode := LXml.DocumentElement.ChildNodes['pods'];
  if LPodsNode.ChildNodes.Count > 1 then
    Assert(FPodIndex > -1, 'Pod index is required to be set for multi-pod tournaments.');
  if FPodIndex = -1 then
    FPodIndex := 0;

  // Update rounds from file.
  Result := UpdateRounds(LPodsNode.ChildNodes[FPodIndex].ChildNodes['rounds']);
end;

function TVGCTournament.Update: Boolean;
begin
  Assert(FMainXmlFileName <> '', ERR_MAIN_XML_REQUIRED);

  Result := Update(FMainXmlFileName);
end;

function TVGCTournament.UpdateRounds(const ARoundsNode: IXMLNode): Boolean;
var
  LOldRoundCount: Integer;
  LUpdatedRounds: array of Integer;
  I: Integer;
begin
  Assert(Assigned(ARoundsNode));

  Logger.Log('Updating tournament...', 3);
  LOldRoundCount := FRoundCount;
  FRoundCount := ARoundsNode.ChildNodes.Count;
  Result := False;
  LUpdatedRounds := [];
  try
    if LOldRoundCount > FRoundCount then
      raise Exception.CreateFmt('Invalid round count (%d)', [FRoundCount]);

    Logger.Log('Received %d rounds (%d previously stored).', [FRoundCount, LOldRoundCount], 3);
    SetLength(FRounds, FRoundCount);
    // Update already existing rounds.
    for I := 0 to LOldRoundCount - 1 do
      if not Rounds[I].IsEnded then
      begin
        Logger.Log('Updating round %d.', [I], 4);
        Assert(EndRound(I, ARoundsNode.ChildNodes[I]) or (I = FRoundCount - 1));
        LUpdatedRounds := LUpdatedRounds + [I];
      end;
    // Create and update "new" rounds.
    for I := LOldRoundCount to FRoundCount - 1 do
    begin
      Logger.Log('Creating new round %d.', [I], 4);
      FRounds[I] := CreateNewRound(I, ARoundsNode.ChildNodes[I]);
      if not EndRound(I, ARoundsNode.ChildNodes[I]) then
      begin
        Assert(I = FRoundCount - 1);
        Logger.Log('New un-finished round: %d.', [I], 5);
        Result := True;
      end;
      LUpdatedRounds := LUpdatedRounds + [I];
    end;

    if Length(LUpdatedRounds) > 0 then
      AfterUpdate(LUpdatedRounds, Result);

    Logger.Log('Tournament update successfully concluded.', 3);
  except
    for I := LOldRoundCount to FRoundCount - 1 do
      FreeAndNil(FRounds[I]);
    FRoundCount := LOldRoundCount;
    SetLength(FRounds, FRoundCount);
    raise;
  end;
end;

end.
