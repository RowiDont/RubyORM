require 'associatable'

describe 'AssocOptions' do
  describe 'BelongsToOptions' do
    it 'provides defaults' do
      options = BelongsToOptions.new('pilot')

      expect(options.foreign_key).to eq(:pilot_id)
      expect(options.class_name).to eq('Pilot')
      expect(options.primary_key).to eq(:id)
    end

    it 'allows overrides' do
      options = BelongsToOptions.new('human',
                                     foreign_key: :human_id,
                                     class_name: 'Human',
                                     primary_key: :human_id
      )

      expect(options.foreign_key).to eq(:human_id)
      expect(options.class_name).to eq('Human')
      expect(options.primary_key).to eq(:human_id)
    end
  end

  describe 'HasManyOptions' do
    it 'provides defaults' do
      options = HasManyOptions.new('pilots', 'Rank')

      expect(options.foreign_key).to eq(:rank_id)
      expect(options.class_name).to eq('Pilot')
      expect(options.primary_key).to eq(:id)
    end

    it 'allows overrides' do
      options = HasManyOptions.new('dogs', 'Human',
                                   foreign_key: :owner_id,
                                   class_name: 'Dog',
                                   primary_key: :human_id
      )

      expect(options.foreign_key).to eq(:owner_id)
      expect(options.class_name).to eq('Dog')
      expect(options.primary_key).to eq(:human_id)
    end
  end

  describe 'AssocOptions' do
    before(:all) do
      class Ship < SQLObject
        self.finalize!
      end

      class Pilot < SQLObject
        self.finalize!
      end

      class Rank < SQLObject
        self.finalize!
      end
    end

    it '#model_class returns class of associated object' do
      options = BelongsToOptions.new('pilot')
      expect(options.model_class).to eq(Pilot)

      options = HasManyOptions.new('pilots', 'Rank')
      expect(options.model_class).to eq(Pilot)
    end

    it '#table_name returns table name of associated object' do
      options = BelongsToOptions.new('pilot')
      expect(options.table_name).to eq('pilots')

      options = HasManyOptions.new('pilots', 'Rank')
      expect(options.table_name).to eq('pilots')
    end
  end
end

describe 'Associatable' do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Ship < SQLObject
      belongs_to :pilot, foreign_key: :pilot_id

      finalize!
    end

    class Pilot < SQLObject
      has_many :ships, foreign_key: :pilot_id
      belongs_to :rank
      finalize!
    end

    class Rank < SQLObject
      has_many :pilots, foreign_key: :rank_id

      finalize!
    end

  end

  describe '#belongs_to' do
    let(:galactica) { Ship.find(1) }
    let(:adama) { Pilot.find(1) }
    let(:rank) { Rank.find(1) }

    it 'fetches `pilot` from `Ship` correctly' do
      expect(galactica).to respond_to(:pilot)
      pilot = galactica.pilot

      expect(pilot).to be_instance_of(Pilot)
      expect(pilot.name).to eq('William Adama')
    end

    it 'fetches `rank` from `Pilot` correctly' do
      expect(adama).to respond_to(:rank)
      rank = adama.rank

      expect(rank).to be_instance_of(Rank)
      expect(rank.name).to eq('Commander')
    end

    it 'returns nil if no associated object' do
      expect(adama.commander_id).to eq(nil)
    end
  end

  # TODO: This stuff right here, right below this line. do it.

  describe '#has_many' do
    let(:lieutenant) { Rank.find(4) }
    # let(:ned_house) { House.find(2) }

    it 'fetches `pilots` from `Rank`' do
      expect(lieutenant).to respond_to(:pilots)
      pilots = lieutenant.pilots

      expect(pilots.length).to eq(2)

      expected_pilot_names = ["Ned Ruggeri", "Lee Adama"]
      2.times do |i|
        pilot = pilots[i]

        expect(pilot).to be_instance_of(Pilot)
        expect(pilot.name).to eq(expected_pilot_names[i])
      end
    end
  end

  describe '::assoc_options' do
    it 'defaults to empty hash' do
      class TempClass < SQLObject
      end

      expect(TempClass.assoc_options).to eq({})
    end

    it 'stores `belongs_to` options' do
      ship_assoc_options = Ship.assoc_options
      pilot_options = ship_assoc_options[:pilot]

      expect(pilot_options).to be_instance_of(BelongsToOptions)
      expect(pilot_options.foreign_key).to eq(:pilot_id)
      expect(pilot_options.class_name).to eq('Pilot')
      expect(pilot_options.primary_key).to eq(:id)
    end

    it 'stores options separately for each class' do
      expect(Ship.assoc_options).to have_key(:pilot)
      expect(Pilot.assoc_options).to_not have_key(:pilot)

      expect(Pilot.assoc_options).to have_key(:rank)
      expect(Rank.assoc_options).to_not have_key(:rank)
    end
  end

  describe '#has_one_through' do
    before(:all) do
      class Ship
        has_one_through :rank, :pilot, :rank

        self.finalize!
      end
    end

    let(:ship) { Ship.find(1) }

    it 'adds getter method' do
      expect(ship).to respond_to(:rank)
    end

    it 'fetches associated `rank` for a `Ship`' do
      rank = ship.rank

      expect(rank).to be_instance_of(Rank)
      expect(rank.name).to eq('Commander')
    end
  end
end
