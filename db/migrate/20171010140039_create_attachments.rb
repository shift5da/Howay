class CreateAttachments < ActiveRecord::Migration[5.1]
  def change
    create_table :attachments do |t|
      t.string :name
      t.string :url
      t.string :content_type
      t.string :ori_filename
      t.timestamps
    end
  end
end
