module StoreField
  if defined? Rails::Railtie
  	class Railtie < Rails::Railtie
  	  initializer 'store_field.insert_into_active_record' do |app|
  	    ActiveSupport.on_load :active_record do
  	      include StoreField
  	    end
  	  end
  	end
  end
end
