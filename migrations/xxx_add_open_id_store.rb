class AddOpenIdStore < Sequel::Migration

  def up
    create_table  :open_id_associations do
      primary_key :id
      File        :server_url, :null => false
      String      :handle, :null => false
      File        :secret, :null => false
      Integer     :issued, :null => false
      Integer     :lifetime, :null => false
      String      :assoc_type, :null => false
    end
    create_table  :open_id_nonces do
      primary_key :id
      String      :server_url, :null => false
      DateTime    :timestamp, :null => false
      String      :salt, :null => false
    end
  end

  def down
    drop_table    :open_id_associations
    drop_table    :open_id_nonces
  end

end