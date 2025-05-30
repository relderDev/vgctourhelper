unit Pokemon.Constants;

interface

const
  POKEMON_NULL_DATA = 'NULL';
  POKEMON_STATS: array[0..5] of string = ('HP', 'Atk', 'Def', 'Spa', 'SpD', 'Spe');
  POKEMON_ITEM = ' @ %Item%';
  POKEMON_GENDER = ' (%Gender%)';
  POKEMON_FIRST_ROW = '%Pokemon%';
  POKEMON_FIRST_ROW_NICK = '%Nickname% (%Pokemon%)';
  POKEMON_CTS_TEMPLATE_BODY: array[0..7] of string = (
    'Ability', 'Level', 'Shiny', 'TeraType', 'EVs', 'Nature', 'IVs', 'Moves'
  );
  POKEMON_OTS_TEMPLATE_BODY: array[0..4] of string = (
    'Ability', 'Level', 'Shiny', 'TeraType', 'Moves'
  );
  POKEMON_TRANSLATABLE_DATA: array[0..9] of string = (
    'Pokemon', 'Item', 'Ability', 'Type1', 'Type2', 'TeraType', 'Move0', 'Move1', 'Move2', 'Move3'
  );
  POKEMON_ASSETS_DATA: array[0..2] of string = ('Pokemon', 'Type', 'Item');
  DEFAULT_DATA_PATH: array[0..2] of string = ('{App}', 'Resources', 'Data');
  DEFAULT_ASSETS_PATH: array[0..2] of string = ('{App}', 'Resources', 'Assets');
  MOVES_RANGE = [0..3];
  TYPES_RANGE = [1..2];
implementation

end.
