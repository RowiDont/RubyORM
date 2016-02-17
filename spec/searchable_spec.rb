require 'searchable'

describe 'Searchable' do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Ship < SQLObject
      finalize!
    end

    class Pilot < SQLObject
      finalize!
    end
  end

  it '#where searches with single criterion' do
    ships = Ship.where(name: 'Battlestar Galactica')
    ship = ships.first

    expect(ships.length).to eq(1)
    expect(ship.name).to eq('Battlestar Galactica')
  end

  it '#where can return multiple objects' do
    pilots = Pilot.where(rank_id: 4)
    expect(pilots.length).to eq(2)
  end

  it '#where searches with multiple criteria' do
    pilots = Pilot.where(name: 'Ned Ruggeri', rank_id: 4)
    expect(pilots.length).to eq(1)

    pilot = pilots[0]
    expect(pilot.name).to eq('Ned Ruggeri')
    expect(pilot.rank_id).to eq(4)
  end

  it '#where returns [] if nothing matches the criteria' do
    expect(Pilot.where(name: 'The ghost of christmas past')).to eq([])
  end
end
