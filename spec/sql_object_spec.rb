require_relative '../RubyRM/sql_object'
require_relative '../RubyRM/db_connection'

describe RubyRM do
  before(:each) { DBConnection.reset(true) }
  after(:each) { DBConnection.reset(true) }

  context 'before ::finalize!' do
    before(:each) do
      class Pilot < RubyRM
      end
    end

    after(:each) do
      Object.send(:remove_const, :Pilot)
    end

    describe '::table_name' do
      it 'generates default name' do
        expect(Pilot.table_name).to eq('pilots')
      end
    end

    describe '::table_name=' do
      it 'sets table name' do
        class Human < RubyRM
          self.table_name = 'humans'
        end

        expect(Human.table_name).to eq('humans')

        Object.send(:remove_const, :Human)
      end
    end

    describe '::columns' do
      it 'returns a list of all column names as symbols' do
        expect(Pilot.columns).to eq([:id, :name, :commander_id, :rank_id])
      end

      it 'only queries the DB once' do
        expect(DBConnection).to(
          receive(:execute2).exactly(1).times.and_call_original)
        3.times { Pilot.columns }
      end
    end

    describe '#attributes' do
      it 'returns @attributes hash byref' do
        pilot_attributes = {name: 'Rafi', commander_id: 3, rank_id: 5}
        t = Pilot.new
        t.instance_variable_set('@attributes', pilot_attributes)

        expect(t.attributes).to equal(pilot_attributes)
      end

      it 'lazily initializes @attributes to an empty hash' do
        t = Pilot.new

        expect(t.instance_variables).not_to include(:@attributes)
        expect(t.attributes).to eq({})
        expect(t.instance_variables).to include(:@attributes)
      end
    end
  end

  context 'after ::finalize!' do
    before(:all) do
      class Pilot < RubyRM
        self.finalize!
      end

      class Ship < RubyRM
        self.table_name = 'ships'

        self.finalize!
      end
    end

    after(:all) do
      Object.send(:remove_const, :Pilot)
      Object.send(:remove_const, :Ship)
    end

    describe '::finalize!' do
      it 'creates getter methods for each column' do
        t = Pilot.new
        expect(t.respond_to? :something).to be false
        expect(t.respond_to? :name).to be true
        expect(t.respond_to? :id).to be true
        expect(t.respond_to? :rank_id).to be true
        expect(t.respond_to? :commander_id).to be true
      end

      it 'creates setter methods for each column' do
        t = Pilot.new
        t.name = "Anikin Skywalker"
        t.id = 78
        t.commander_id = 2
        t.rank_id = 3
        expect(t.name).to eq 'Anikin Skywalker'
        expect(t.id).to eq 78
        expect(t.commander_id).to eq 2
        expect(t.rank_id).to eq 3
      end

      it 'created getter methods read from attributes hash' do
        t = Pilot.new
        t.instance_variable_set(:@attributes, {name: "Anikin Skywalker"})
        expect(t.name).to eq 'Anikin Skywalker'
      end

      it 'created setter methods use attributes hash to store data' do
        t = Pilot.new
        t.name = "Anikin Skywalker"

        expect(t.instance_variables).to include(:@attributes)
        expect(t.instance_variables).not_to include(:@name)
        expect(t.attributes[:name]).to eq 'Anikin Skywalker'
      end
    end

    describe '#initialize' do
      it 'calls appropriate setter method for each item in params' do
        # We have to set method expectations on the pilot object *before*
        # #initialize gets called, so we use ::allocate to create a
        # blank Pilot object first and then call #initialize manually.
        t = Pilot.allocate

        expect(t).to receive(:name=).with('Rafi')
        expect(t).to receive(:id=).with(100)
        expect(t).to receive(:commander_id=).with(4)
        expect(t).to receive(:rank_id=).with(5)

        t.send(:initialize, {name: 'Rafi', id: 100, commander_id: 4, rank_id: 5})
      end

      it 'throws an error when given an unknown attribute' do
        expect do
          Pilot.new(favorite_band: 'Not Coldplay')
        end.to raise_error "unknown attribute 'favorite_band'"
      end
    end

    describe '::all, ::parse_all' do
      it '::all returns all the rows' do
        pilots = Pilot.all
        expect(pilots.count).to eq(5)
      end

      it '::parse_all turns an array of hashes into objects' do
        hashes = [
          { name: 'Rafi', id: 100, commander_id: 4, rank_id: 5 },
          { name: 'Anakin Skywalker', id: 150, commander_id: 2, rank_id: 3 }
        ]

        pilots = Pilot.parse_all(hashes)
        expect(pilots.length).to eq(2)
        hashes.each_index do |i|
          expect(pilots[i].name).to eq(hashes[i][:name])
          expect(pilots[i].commander_id).to eq(hashes[i][:commander_id])
        end
      end

      it '::all returns a list of objects, not hashes' do
        pilots = Pilot.all
        pilots.each { |pilot| expect(pilot).to be_instance_of(Pilot) }
      end
    end

    describe '::find' do
      it 'fetches single objects by id' do
        t = Pilot.find(1)

        expect(t).to be_instance_of(Pilot)
        expect(t.id).to eq(1)
      end

      it 'returns nil if no object has the given id' do
        expect(Pilot.find(123)).to be_nil
      end
    end

    describe '#attribute_values' do
      it 'returns array of values' do
        ship = Ship.new(id: 123, name: 'Milenium Falcon', pilot_id: 4)

        expect(ship.attribute_values).to eq([123, 'Milenium Falcon', 4])
      end
    end

    describe '#insert' do
      let(:ship) { Ship.new(name: 'Death Star', pilot_id: 4) }
      before(:each) { ship.insert }

      it 'inserts a new record' do
        expect(Ship.all.count).to eq(6)
      end

      it 'sets the id once the new record is saved' do
        expect(ship.id).to eq(DBConnection.last_insert_row_id)
      end

      it 'creates a new record with the correct values' do
        ship2 = Ship.find(ship.id)

        expect(ship2.name).to eq('Death Star')
        expect(ship2.pilot_id).to eq(4)
      end
    end

    describe '#update' do
      it 'saves updated attributes to the DB' do
        pilot = Pilot.find(2)

        pilot.name = 'Jon Snow'
        pilot.update

        # pull the pilot again
        pilot = Pilot.find(2)
        expect(pilot.name).to eq('Jon Snow')
      end
    end

    describe '#save' do
      it 'calls #insert when record does not exist' do
        pilot = Pilot.new
        expect(pilot).to receive(:insert)
        pilot.save
      end

      it 'calls #update when record already exists' do
        pilot = Pilot.find(1)
        expect(pilot).to receive(:update)
        pilot.save
      end
    end

    describe '#first' do
      it 'retrieves the first record' do
        pilot = Pilot.first
        expect(pilot.id).to eq(1)
      end
    end

    describe '#last' do
      it 'retrieves the last record' do
        pilot = Pilot.new({ name: 'Rafi', commander_id: 4, rank_id: 5 })
        pilot.save

        last = Pilot.last
        expect(last.name).to eq('Rafi')
      end
    end
  end
end
