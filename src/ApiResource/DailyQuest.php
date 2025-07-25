<?php

namespace App\ApiResource;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Patch;
use App\Enum\DailyQuestStatusEnum;
use App\State\DailyQuestStateProcessor;
use App\State\DailyQuestStateProvider;
use Symfony\Component\Serializer\Annotation\Ignore;

#[ApiResource(
    shortName: 'Quest',
    operations: [
        new GetCollection(),
        new Get(),
        new Patch(
            processor: DailyQuestStateProcessor::class,
        ),
    ],
    provider: DailyQuestStateProvider::class,
)]
class DailyQuest
{
    #[Ignore]
    public readonly \DateTimeInterface $day;

    public string $questName;
    public string $description;
    public int $difficultyLevel;
    public DailyQuestStatusEnum $status;
    public \DateTimeInterface $lastUpdated;
    /**
     * @var QuestTreasure[]
     */
    public array $treasures;

    public function __construct(\DateTimeInterface $day)
    {
        $this->day = $day;
    }

    #[ApiProperty(readable:false, identifier: true)]
    public function getDayString(): string
    {
        return $this->day->format('Y-m-d');
    }
}
