require "openid/store/interface"
require "base64"

# not in OpenID module to avoid namespace conflict
class OpenidSequelStore < OpenID::Store::Interface
  def store_association(server_url, assoc)
    remove_association(server_url, assoc.handle)
    Association.insert({
      :server_url => server_url,
      :handle     => assoc.handle,
      :secret     => Base64.encode64(assoc.secret),
      :issued     => assoc.issued.to_i,
      :lifetime   => assoc.lifetime,
      :assoc_type => assoc.assoc_type,
    })
  end

  def get_association(server_url, handle=nil)
    assocs = if handle.blank?
      Association.filter(:server_url => server_url).all
    else
      Association.filter(:server_url => server_url, :handle => handle).all
    end

    assocs.reverse.each do |assoc|
      a = assoc.from_record
      if a.expires_in == 0
        assoc.delete
      else
        return a
      end
    end if assocs.any?
  
    return nil
  end

  def remove_association(server_url, handle)
    Association.filter(:server_url => server_url, :handle => handle).delete>0
  end

  def use_nonce(server_url, timestamp, salt)
    return false if Sso::Nonce.filter(:server_url => server_url, :timestamp => timestamp, :salt => salt).first
    return false if (timestamp - Time.now.to_i).abs > OpenID::Nonce.skew
    Nonce.insert(:server_url => server_url, :timestamp => timestamp, :salt => salt)
    return true
  end

  def cleanup_nonces
    now = Time.now.to_i
    Nonce.filter{:timestamp > now+OpenID::Nonce.skew | :timestamp < now-OpenID::Nonce.skew}.delete
  end

  def cleanup_associations
    now = Time.now.to_i
    Association.filter{:issued + :lifetime > now}.delete
  end

end