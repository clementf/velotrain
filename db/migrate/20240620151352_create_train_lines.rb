class CreateTrainLines < ActiveRecord::Migration[7.1]
  def change
    create_table :train_lines do |t|
      t.string :code
      t.geometry :geom

      t.timestamps
    end
  end
end
