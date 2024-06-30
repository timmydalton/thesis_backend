defmodule ThesisBackend.Repo.Migrations.VietnameseUnaccent do
  use Ecto.Migration

  def up do
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
  end

  def down do
    execute("""
      DROP FUNCTION IF EXISTS unaccent_string(text)
    """)
  end
end
