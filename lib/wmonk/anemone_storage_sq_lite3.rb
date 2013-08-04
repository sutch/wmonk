require 'anemone/storage/sqlite3'
module Wmonk
  class AnemoneStorageSQLite3 < Anemone::Storage::SQLite3

    def create_schema
      @db.execute_batch <<SQL
          create table if not exists anemone_storage (
            id INTEGER PRIMARY KEY ASC,
            key TEXT,
            data BLOB,
            code INTEGER,
            is_not_found INTEGER,
            is_redirect INTEGER,
            redirect_to TEXT,
            content_type TEXT,
            retrieved_at INTEGER
          );
          create index  if not exists anemone_key_idx on anemone_storage (key);
SQL
    end

    def []=(url, value)
      data = Marshal.dump(value)
      code = value.code
      is_not_found = value.code.nil? ? nil : (value.not_found? ? 1 : 0)
      is_redirect = value.code.nil? ? nil : (value.redirect? ? 1 : 0)
      redirect_to = value.code.nil? ? nil : value.redirect_to.to_s
      content_type = value.code.nil? ? nil : value.content_type.to_s
      content_type.force_encoding('UTF-8') if content_type.respond_to?(:force_encoding)  # necessary to prevent SQLite3 from occasionally saving as a hex value
      if has_key?(url)
        @db.execute("UPDATE anemone_storage SET data = :data, code = :code, is_not_found = :is_not_found, is_redirect = :is_redirect, redirect_to = :redirect_to, content_type = :content_type WHERE key = :key",
          :data => data, :code => code, :is_not_found => is_not_found, :is_redirect => is_redirect, :redirect_to => redirect_to, :content_type => content_type, :key => url.to_s)
      else
        @db.execute('INSERT INTO anemone_storage (data, key, code, is_not_found, is_redirect, redirect_to, content_type) VALUES(:data, :key, :code, :is_not_found, :is_redirect, :redirect_to, :content_type)',
          :data => data, :code => code, :is_not_found => is_not_found, :is_redirect => is_redirect, :redirect_to => redirect_to, :content_type => content_type, :key => url.to_s)
      end
    end

    def not_visited_urls
      @db.execute("SELECT key FROM anemone_storage WHERE code IS NULL ORDER BY id").map{|t| t[0]}
    end

  end
end