defmodule ThesisBackend.Repo.Migrations.CreateFunction do
  use Ecto.Migration

  def change do
    execute("""
      CREATE OR REPLACE FUNCTION public.vietnamese_unaccent(text)
      RETURNS text
      LANGUAGE plpgsql
      AS $function$
      DECLARE
          input_string text := $1;
      BEGIN

      input_string := translate(input_string, 'áàãạảAÁÀÃẠẢăắằẵặẳĂẮẰẴẶẲâầấẫậẩÂẤẦẪẬẨ', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      input_string := translate(input_string, 'éèẽẹẻEÉÈẼẸẺêếềễệểÊẾỀỄỆỂ', 'eeeeeeeeeeeeeeeeeeeeeeee');
      input_string := translate(input_string, 'íìĩịỉIÍÌĨỊỈ', 'iiiiiiiiiii');
      input_string := translate(input_string, 'óòõọỏOÓÒÕỌỎôốồỗộổÔỐỒỖỘỔơớờỡợởƠỚỜỠỢỞ', 'ooooooooooooooooooooooooooooooooooo');
      input_string := translate(input_string, 'úùũụủUÚÙŨỤỦưứừữựửƯỨỪỮỰỬ', 'uuuuuuuuuuuuuuuuuuuuuuu');
      input_string := translate(input_string, 'ýỳỹỵỷYÝỲỸỴỶ', 'yyyyyyyyyyy');
      input_string := translate(input_string, 'dđĐD', 'dddd');

      return input_string;
      END;
      $function$
    """)

    execute """
      CREATE OR REPLACE FUNCTION public.slugify("value" TEXT)
      RETURNS TEXT AS $$
        -- removes accents (diacritic signs) from a given string --
        WITH "unaccented" AS (
          SELECT vietnamese_unaccent("value") AS "value"
        ),
        -- lowercases the string
        "lowercase" AS (
          SELECT lower("value") AS "value"
          FROM "unaccented"
        ),
        -- replaces anything that's not a letter, number, hyphen('-'), or underscore('_') with a hyphen('-')
        "hyphenated" AS (
          SELECT regexp_replace("value", '[^a-z0-9\\-_]+', '-', 'gi') AS "value"
          FROM "lowercase"
        ),
        -- trims hyphens('-') if they exist on the head or tail of the string
        "trimmed" AS (
          SELECT regexp_replace(regexp_replace("value", '\\-+$', ''), '^\\-', '') AS "value"
          FROM "hyphenated"
        )
        SELECT "value" FROM "trimmed";
      $$ LANGUAGE SQL STRICT IMMUTABLE;
    """
  end
end
