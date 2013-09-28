# A Storage class for Wmonk which uses SQLite3
module Wmonk
  class AnemoneStorage

    # Return AnemonePage for last exchange of request for URL
    def [](url)
      u = Url.find_by value: url.to_s
      if u
        exchange = Exchange.where(url: u).order('created_at DESC').first
        if exchange
          Marshal.load(exchange.anemone_page)
        end
      end
    end

    # Save AnemonePage for URL as an exchange
    def []=(url, page)
      u = Url.find_or_create_by!(value: url.to_s)
      return if !page.fetched?

      unless page.body.nil?
        page.data.body_digest = Digest::SHA512.base64digest(page.body)
        body = Body.find_or_create_by(digest: page.data.body_digest) do |b|
          b.value = page.body
        end
        content_type = ContentType.find_or_create_by!(value: page.content_type)
        content_item = ContentItem.find_or_create_by!(content_type_id: content_type.id, body_id: body.id)
      end

      if page.data.exchange_id.nil?
        exchange = Exchange.create! do |e|
          e.url = u
          e.status_code = page.code
          page.discard_doc!
          e.anemone_page = Marshal.dump(page)
          e.content_item_id = content_item.id unless content_item.nil?
        end
        page.data.exchange_id = exchange.id
      else
        exchange = Exchange.find_by(id: page.data.exchange_id)
      end

      exchange

      #data = Marshal.dump(value)
      #if has_key?(url)
      #  @db.execute('UPDATE anemone_storage SET data = ? WHERE key = ?', data, url.to_s)
      #else
      #  @db.execute('INSERT INTO anemone_storage (data, key) VALUES(?, ?)', data, url.to_s)
      #end
    end

    def delete(url)
      puts "!!!!!!!!!!!!!!!!!! delete"
      #page = self[url]
      #@db.execute('DELETE FROM anemone_storage WHERE key = ?', url.to_s)
      #page
    end

    def each
      puts "!!!!!!!!!!!!!!!!!! each"
      #@db.execute("SELECT key, data FROM anemone_storage ORDER BY id") do |row|
      #  value = Marshal.load(row[1])
      #  yield row[0], value
      #end
    end

    def merge!(hash)
      hash.each { |key, value| self[key] = value }
      self
    end

    def size
      puts "!!!!!!!!! size"
      #@db.get_first_value('SELECT COUNT(id) FROM anemone_storage')
    end

    def keys
      puts "!!!!!!!! keys"
      #@db.execute("SELECT key FROM anemone_storage ORDER BY id").map{|t| t[0]}
    end

    def has_key?(url)
      !!Url.find_by(value: url.to_s)
      #!!@db.get_first_value('SELECT id FROM anemone_storage WHERE key = ?', url.to_s)
    end

    def close
      #@db.close
    end

    private

#    def create_schema
      #@db.execute_batch <<SQL
      #    create table if not exists anemone_storage (
      #      id INTEGER PRIMARY KEY ASC,
      #      key TEXT,
      #      data BLOB
      #    );
      #    create index  if not exists anemone_key_idx on anemone_storage (key);
#SQL
#    end

#    def load_page(hash)
#      BINARY_FIELDS.each do |field|
#        hash[field] = hash[field].to_s
#      end
#      Page.from_hash(hash)
#    end

  end
end
