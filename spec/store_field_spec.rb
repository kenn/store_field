require 'spec_helper'

ActiveRecord::Base.connection.create_table :users, force: true do |t|
  t.text :storage
end

class User < ActiveRecord::Base
  store :storage
  store_field :preference
  store_field :count_caches
  store_field :notified, type: Set
  store_field :displayed, type: Set
  store_field :funnel, type: Set
end

describe StoreField do
  before do
    @user = User.new
  end

  it 'raises when store is not defined beforehand' do
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :notified } }.to_not raise_error(ArgumentError)
    expect { Class.new(ActiveRecord::Base) {                 store_field :notified } }.to     raise_error(ArgumentError)
  end

  it 'raises when invalid option is given' do
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :notified, type: File } }.to raise_error(ArgumentError)
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :notified, in: :bogus } }.to raise_error(ArgumentError)
  end

  it 'initializes with the specified type' do
    @user.preference.should == {}
    @user.notified.should == Set.new
  end

  it 'sets and unsets keywords' do
    @user.set_notified(:welcome)
    @user.set_notified(:first_deposit)

    # Consume balance, notify once and only once
    @user.set_notified(:balance_low)
    @user.set_notified(:balance_negative)

    # Another deposit, restore balance
    @user.unset_notified(:balance_low)
    @user.unset_notified(:balance_negative)

    @user.notified.should == Set.new([:welcome, :first_deposit])
  end

  it 'saves in-line' do
    @user.set_notified(:welcome).save.should == true
    @user.reload
    @user.set_notified?(:welcome).should == true
  end
end
