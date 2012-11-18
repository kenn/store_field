require 'spec_helper'

ActiveRecord::Base.connection.create_table :users, force: true do |t|
  t.text :storage
end

class User < ActiveRecord::Base
  store :storage
  store_field :tutorials, keys: [ :quick_start ]
  store_field :delivered, type: Set, values: [ :welcome, :balance_low ]

  validates :tutorials_quick_start, inclusion: { in: [ :started, :finished ], allow_nil: true }
end

describe StoreField do
  before do
    @user = User.new
  end

  it 'raises when store is not defined beforehand' do
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :delivered } }.to_not raise_error(ScriptError)
    expect { Class.new(ActiveRecord::Base) {                 store_field :delivered } }.to     raise_error(ScriptError)
  end

  it 'raises when invalid option is given' do
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :delivered, type: File } }.to raise_error(ArgumentError)
    expect { Class.new(ActiveRecord::Base) { store :storage; store_field :delivered, in: :bogus } }.to raise_error(ArgumentError)
  end

  it 'initializes with the specified type' do
    @user.tutorials.should == {}
    @user.delivered.should == Set.new
    @user.valid?.should == true
  end

  describe Hash do
    it 'validates Hash' do
      @user.tutorials_quick_start = :started
      @user.valid?.should == true
      @user.errors.empty?.should == true

      @user.tutorials_quick_start = :bogus
      @user.valid?.should == false
      @user.errors.has_key?(:tutorials_quick_start).should == true
    end
  end

  describe Set do
    it 'validates Set' do
      @user.set_delivered(:welcome)
      @user.valid?.should == true
      @user.errors.empty?.should == true

      @user.set_delivered(:bogus)
      @user.valid?.should == false
      @user.errors.has_key?(:delivered).should == true
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
end
