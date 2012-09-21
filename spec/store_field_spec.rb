require 'spec_helper'

ActiveRecord::Base.connection.create_table :users, force: true do |t|
  t.text :storage
end

class User < ActiveRecord::Base
  store :storage
  store_field :tutorials
  store_field :delivered, type: Set, values: [ :welcome, :balance_low ]
end

describe StoreField do
  before do
    @user = User.new
  end

  it 'raises when store is not defined beforehand' do
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :delivered } }.to_not raise_error(ArgumentError)
    expect { Class.new(ActiveRecord::Base) {                 store_field :delivered } }.to     raise_error(ArgumentError)
  end

  it 'raises when invalid option is given' do
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :delivered, type: File } }.to raise_error(ArgumentError)
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :delivered, in: :bogus } }.to raise_error(ArgumentError)
  end

  it 'initializes with the specified type' do
    @user.tutorials.should == {}
    @user.delivered.should == Set.new
  end

  it 'raises when invalid value is given for Set' do
    expect {
      @user.set_delivered(:bogus)
    }.to raise_error(ArgumentError)
  end

  it 'sets and unsets keywords' do
    @user.set_delivered(:welcome)

    # Consume balance, notify once and only once
    @user.set_delivered(:balance_low)

    # Another deposit, restore balance
    @user.unset_delivered(:balance_low)

    @user.delivered.should == Set.new([:welcome])
  end

  it 'saves in-line' do
    @user.set_delivered(:welcome).save.should == true
    @user.reload
    @user.set_delivered?(:welcome).should == true
  end
end
