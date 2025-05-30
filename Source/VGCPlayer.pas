unit VGCPlayer;

interface

uses
  Generics.Collections, Generics.Defaults, Xml.XMLIntf,
  AK.Classes,
  Pokemon;

type
  TVGCPlayer = class;

  TVGCResult = TPair<Integer, TVGCPlayer>;
  TVGCResults = array of TVGCResult;
  TVGCPlayerProc = reference to procedure (const APlayer: TVGCPlayer);
  TVGCResultProc = reference to procedure (const ARoundNumber: Integer;
    const AOpponent: TVGCPlayer; const AHasWon: Boolean);

  TVGCPlayer = class
  strict private
    FGUID: string;
    FData: TAKDynRecord;
    FPokepasteText: string;
    FTeam: TPokemonTeam;
    FWins: Integer;
    FLosses: Integer;
    FResults: TVGCResults;
    procedure EnumOpponents(const AProc: TVGCPlayerProc; const AIncludeByes: Boolean = True);
    procedure SetPokepasteText(const APokepasteText: string);
    function GetScore: string;
    function GetMatchCount: Integer;
    function GetWinrate: Double;
    function GetOppWinrate: Double;
    function GetOppOppWinrate: Double;
    function GetOppWinratePerc: string;
    function GetOppOppWinratePerc: string;
  private
    FId: string;
  public
    property Id: string read FId;
    property GUID: string read FGUID;
    property Data: TAKDynRecord read FData;
    property PokepasteText: string read FPokepasteText write SetPokepasteText;
    property Team: TPokemonTeam read FTeam;
    property CurrentWins: Integer read FWins;
    property CurrentLosses: Integer read FLosses;
    property Score: string read GetScore;
    property MatchCount: Integer read GetMatchCount;
    property Winrate: Double read GetWinrate;
    property OppWinrate: Double read GetOppWinrate;
    property OppOppWinrate: Double read GetOppOppWinrate;
    property OppWinratePerc: string read GetOppWinratePerc;
    property OppOppWinratePerc: string read GetOppOppWinratePerc;

    /// <summary>Loads player data from XML.</summary>
    procedure ReadFromXmlNode(const AData: IXMLNode);
    /// <summary>Applies a win to the player and registers the result.</summary>
    procedure Win(const AOpponent: TVGCPlayer);
    /// <summary>Applies a loss to the player and registers the result.</summary>
    procedure Loss(const AOpponent: TVGCPlayer);
    /// <summary>Enumerates all the results of the player.</summary>
    /// <remarks>The opponent argument is nil for BYE rounds.</remarks>
    procedure EnumResults(const AProc: TVGCResultProc);
    /// <summary>First name and last name.</summary>
    function AsString: string;
    /// <summary>
    ///  Expands %Team%, %Player% and %Score% macros in the given template in
    ///  addiction to the data macros.
    /// </summary>
    function ApplyToTemplate(const ATeamlistTemplate, APokemonTemplate: string;
      const AApplyTranslation, AIncludeScore: Boolean): string;

    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>Comparer to sort players in standings.</summary>
  TVGCPlayerComparer = class(TComparer<TVGCPlayer>)
  strict private
    FTournamentWinner: string;
  public
    function Compare(const Left, Right: TVGCPlayer): Integer; override;
    constructor Create(const ATournamentWinner: string);
  end;

  /// <summary>List of players with added utilities.</summary>
  TVGCPlayers = class
  strict protected
    FItems: TObjectDictionary<string, TVGCPlayer>;
    function GetPlayer(const APlayerId: string): TVGCPlayer;
    function GetCount: Integer;
  public
    property Players[const AId: string]: TVGCPlayer read GetPlayer; default;
    property Count: Integer read GetCount;
    procedure AddPlayer(const APlayer: TVGCPlayer);
    procedure RemovePlayer(const APlayerId: string);
    procedure Clear;
    procedure EnumPlayers(const AProc: TVGCPlayerProc);
    procedure EnumPlayersSorted(const AProc: TVGCPlayerProc;
      const ATournamentWinner: string = '');
    function IsIncluded(const APlayerId: string): Boolean;
    function FindPlayer(const APlayerId: string): TVGCPlayer;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils, StrUtils, Math,
  AK.Utils;

function CompareWinrates(const ALeft, ARight: Double): Integer;
begin
  Result := Ceil(ALeft*100) - Ceil(ARight*100);
end;

{ TVGCPlayer }

function TVGCPlayer.ApplyToTemplate(const ATeamlistTemplate, APokemonTemplate: string;
  const AApplyTranslation, AIncludeScore: Boolean): string;
var
  LTeamPart: string;
begin
  Assert(Assigned(FTeam));

  Result := ATeamlistTemplate;
  if ContainsText(Result, '%Team%') then
  begin
    LTeamPart := FTeam.ApplyToTemplate(APokemonTemplate, AApplyTranslation);
    Result := ReplaceAndIndent(Result, '%Team%', LTeamPart);
  end;
  FData.ExpandMacros(Result, procedure (var AMacroName: string)
    begin
      if MatchText(AMacroName, ['Wins', 'Losses']) and not AIncludeScore then
        AMacroName := '';
    end);
end;

function TVGCPlayer.AsString: string;
begin
  Result := FData.GetString('FirstName', '[first name]') + ' ' +
    FData.GetString('LastName', '[last name]');
end;

constructor TVGCPlayer.Create;
begin
  FGUID := CreateCompactGuidStr;
  FData := TAKDynRecord.Create;
  FWins := 0;
  FLosses := 0;
end;

destructor TVGCPlayer.Destroy;
begin
  FreeAndNil(FData);
  FreeAndNil(FTeam);
  inherited;
end;

procedure TVGCPlayer.EnumOpponents(const AProc: TVGCPlayerProc;
  const AIncludeByes: Boolean);
var
  LResult: TVGCResult;
begin
  Assert(Assigned(AProc));

  for LResult in FResults do
    if AIncludeByes or Assigned(LResult.Value) then
      AProc(LResult.Value);
end;

procedure TVGCPlayer.EnumResults(const AProc: TVGCResultProc);
var
  I: Integer;
begin
  Assert(Assigned(AProc));

  for I := 0 to High(FResults) do
    AProc(I + 1, FResults[I].Value, FResults[I].Key = 1);
end;

function TVGCPlayer.GetMatchCount: Integer;
begin
  Result := CurrentWins + CurrentLosses;
end;

function TVGCPlayer.GetOppOppWinrate: Double;
var
  LSum: Double;
  LTot: Integer;
begin
  LSum := 0;
  LTot := 0;
  EnumOpponents(procedure (const AOpponent: TVGCPlayer)
    begin
      LSum := LSum + AOpponent.OppWinrate;
      Inc(LTot);
    end, False);
  Result := LSum / LTot;
end;

function TVGCPlayer.GetOppOppWinratePerc: string;
begin
  Result := FormatFloat('0.00', GetOppOppWinrate * 100);
end;

function TVGCPlayer.GetOppWinrate: Double;
var
  LSum: Double;
  LTot: Integer;
begin
  LSum := 0;
  LTot := 0;
  EnumOpponents(procedure (const AOpponent: TVGCPlayer)
    begin
      LSum := LSum + AOpponent.Winrate;
      Inc(LTot);
    end, False);
  Result := LSum / LTot;
end;

function TVGCPlayer.GetOppWinratePerc: string;
begin
  Result := FormatFloat('0.00', GetOppWinrate * 100);
end;

function TVGCPlayer.GetScore: string;
begin
  Result := Format('%d - %d', [CurrentWins, CurrentLosses]);
end;

function TVGCPlayer.GetWinrate: Double;
begin
  Result := CurrentWins / MatchCount;
  if Result < 0.25 then
    Result := 0.25;
end;

procedure TVGCPlayer.Loss(const AOpponent: TVGCPlayer);
var
  LLength: Integer;
begin
  Inc(FLosses);
  FData['Losses'] := FLosses;
  LLength := Length(FResults);
  SetLength(FResults, LLength + 1);
  FResults[LLength] := TPair<Integer, TVGCPlayer>.Create(0, AOpponent);
end;

procedure TVGCPlayer.ReadFromXmlNode(const AData: IXMLNode);
begin
  FData.Clear;
  FId := AData.Attributes['userid'];
  FData.LoadFromXML(AData);
  FData['Wins'] := 0;
  FData['Losses'] := 0;
end;

procedure TVGCPlayer.SetPokepasteText(const APokepasteText: string);
var
  LTeam: TPokemonTeam;
begin
  LTeam := TPokemonTeam.Create;
  try
    LTeam.Initialize(FormatLineBreaks(APokepasteText));
    FPokepasteText := APokepasteText;
    FreeAndNil(FTeam);
    FTeam := LTeam;
  except
    FreeAndNil(LTeam);
    raise;
  end;
end;

procedure TVGCPlayer.Win(const AOpponent: TVGCPlayer);
var
  LLength: Integer;
begin
  Inc(FWins);
  FData['Wins'] := FWins;
  LLength := Length(FResults);
  SetLength(FResults, LLength + 1);
  FResults[LLength] := TPair<Integer, TVGCPlayer>.Create(1, AOpponent);
end;

{ TVGCPlayerComparer }

function TVGCPlayerComparer.Compare(const Left, Right: TVGCPlayer): Integer;
begin
  // Winner of the tournament is always less than others.
  if Left.FId = FTournamentWinner then
    Exit(-1);
  if Right.FId = FTournamentWinner then
    Exit(1);
  // compare matchcounts to account for topcut (more matches = in topcut).
  Result := Right.MatchCount - Left.MatchCount;
  // compare wins.
  if Result = 0 then
    Result := Right.CurrentWins - Left.CurrentWins;
  // compare opponents' winrate when wins are equal.
  if Result = 0 then
    Result := CompareWinrates(Right.OppWinrate, Left.OppWinrate);
  // compare opponents' opponent's winrate when opponent's winrate are equal.
  if Result = 0 then
    Result := CompareWinrates(Right.OppOppWinrate, Left.OppOppWinrate);
end;

constructor TVGCPlayerComparer.Create(const ATournamentWinner: string);
begin
  FTournamentWinner := ATournamentWinner;
end;

{ TVGCPlayers }

procedure TVGCPlayers.AddPlayer(const APlayer: TVGCPlayer);
begin
  Assert(not Assigned(FindPlayer(APlayer.FId)),
    Format('Player ID "%s" already registered.', [APlayer.FId]));
  FItems.Add(APlayer.FId, APlayer);
end;

procedure TVGCPlayers.Clear;
begin
  FItems.Clear;
end;

constructor TVGCPlayers.Create;
begin
  FItems := TObjectDictionary<string, TVGCPlayer>.Create([doOwnsValues]);
end;

destructor TVGCPlayers.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TVGCPlayers.EnumPlayers(const AProc: TVGCPlayerProc);
var
  LPlayer: TVGCPlayer;
begin
  Assert(Assigned(AProc));

  for LPlayer in FItems.Values do
    AProc(LPlayer);
end;

procedure TVGCPlayers.EnumPlayersSorted(const AProc: TVGCPlayerProc;
  const ATournamentWinner: string);
var
  LList: TList<TVGCPlayer>;
  LComparer: TVGCPlayerComparer;
  LPlayer: TVGCPlayer;
begin
  Assert(Assigned(AProc));

  LList := TList<TVGCPlayer>.Create(FItems.Values);
  try
    LComparer := TVGCPlayerComparer.Create(ATournamentWinner);
    LList.Sort(LComparer);
    for LPlayer in LList do
      AProc(LPlayer);
  finally
    FreeAndNil(LList);
  end;
end;

function TVGCPlayers.FindPlayer(const APlayerId: string): TVGCPlayer;
begin
  Result := nil;
  if FItems.ContainsKey(APlayerId) then
    Result := FItems[APlayerId];
end;

function TVGCPlayers.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TVGCPlayers.GetPlayer(const APlayerId: string): TVGCPlayer;
begin
  Result := FindPlayer(APlayerId);
  Assert(Assigned(Result), Format('Player ID "%s" not found.', [APlayerId]));
end;

function TVGCPlayers.IsIncluded(const APlayerId: string): Boolean;
begin
  Result := FItems.ContainsKey(APlayerId);
end;

procedure TVGCPlayers.RemovePlayer(const APlayerId: string);
begin
  FItems.Remove(APlayerId);
end;


end.
